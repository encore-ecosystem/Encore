# Memory Model

This is the advanced model and implementation contract. Start with
[Values, Sharing, and Mutation](values-and-sharing.md) for the practical
introduction. A stated runtime invariant is not a claim that every compiler
revision is free of bugs; use the validation guidance below for regressions.

EHIR is a state machine over graph memory. Encore is a source-language layer
which lowers imports, loops, pattern matching and other compound constructs to
that machine; it does not define a second ownership model.

The model has two kinds of runtime data:

- an **inline value** contains its complete payload;
- a **node handle** is an owning edge to an object node.

Every EHIR node handle is owning by definition. Ownership is not an optional
qualifier and there is no borrowed form of an EHIR node handle.

## Values, nodes and type forms

For an aggregate payload type `T`, EHIR and Encore use these forms:

| Form | Meaning |
| --- | --- |
| `T` | the complete aggregate payload stored inline |
| `T<S>` | an owning handle to a node placed in the current stack frame |
| `T<H>` | an owning handle to a heap node |
| `T&` | an owning handle whose stack/heap placement is erased |
| `T*` | a raw machine address, available only through `unsafe` |

`T<S>`, `T<H>` and `T&` have the same one-word handle ABI. `T&` means "either
safe node placement"; it does not mean borrow, weak reference or raw pointer.
A `T&` value can be produced from `T<S>` or `T<H>`, but it cannot be used to
recover a more specific placement without proof.

Primitive values and inline aggregates are values, not object nodes. A value
may contain node handles. Each such handle is still one owning root or edge in
the graph.

```enq
struct Target {
    value: u32
}

let payload = Target{1_u32}       // Target, stored inline
let local = Target<S>{2_u32}      // stack node
let shared = Target<H>{3_u32}     // heap node
```

Node placement is explicit. A compiler must not silently turn a rejected
`T<S>` construction into `T<H>`.

### Inline copying

Copying an inline aggregate creates an independent payload. Primitive fields
are copied, nested inline fields are copied recursively and every nested node
handle gains one owning reference.

```enq
struct Pair {
    left: u32
    target: Target<H>
}

let first = Pair{1_u32, Target<H>{10_u32}}
let second = first
```

`first` and `second` are independent `Pair` payloads, but their `target` fields
are two owning handles to the same node.

An immutable binding is a read-only capability. `mut` may be introduced for a
fresh expression, but cannot be recovered from an immutable path. This closes
the alias-laundering hole where a new binding could manufacture a writer from
a reader:

```enq
let a = Pair{1_u32, Target<H>{10_u32}}
// let mut b = a  // error: mutable-alias-from-readonly
```

A mutable capability can instead be passed directly to a `mut` parameter or
receiver. Ordinary value copies remain ordinary read-only bindings.

### Mutation

`mut` is a deep path capability, not a pointer kind. It permits rebinding and
mutation through every field or element projected from that path. It is
removed by the local-to-SSA pass and must never be represented as `T<S>`.

Function parameters and receivers opt into mutation explicitly with `mut T`.
An ordinary parameter, including ordinary `self`, is read-only. Owning a node
handle does not implicitly grant write access to its payload.

```enq
fn increment(counter: mut Counter&) -> () {
    counter.value += 1_u32
}
```

Mutable standard collections follow the same rule. `Vec[T]`, dictionaries and
similar containers expose heap-node constructors and handle receivers. Copying
their handle shares the collection; an explicit `clone` operation creates an
independent collection.

## Graph-memory foundation

Let the memory state be a directed graph $G = (V, E)$. `V` contains object
nodes and live root vertices such as active function state, globals and native
pins. Each edge in $E$ is one owning EHIR reference. Inline fields in a local
value originate at its root vertex; fields in a node originate at that node.

A node is logically alive while at least one owning path from a live root
requires it to remain alive. Cycles are valid graph structures.

Raw pointers are not graph edges. Safe EHIR never derives lifetime guarantees
from `T*`; code using a raw address must satisfy a separate unsafe contract.

## ERN set operator

For a stable graph snapshot, let $P_G(v)$ be the set reachable from $v$ by zero
or more directed edges. Thus $v \in P_G(v)$. The complement is relative to the
complete vertex set:

$$
\overline{P_G(v)} = V \setminus P_G(v)
$$

Let every vertex outside the candidate region contribute everything it can
reach:

$$
Q_G(v) = \bigcup_{k \in \overline{P_G(v)}} P_G(k)
$$

The Exclusively Reachable Nodes set is:

$$
ERN_G(v) = P_G(v) \setminus Q_G(v)
$$

ERN is a pure set-selection operator. Evaluating it does not mutate $G$.

Root vertices are important. A remaining local, global or native pin lies
outside $P_G(v)$ and its path excludes the referenced object from
$ERN_G(v)$. The owner being released is removed from the snapshot before ERN
is classified.

### Lifetime dominance

For the current graph snapshot, $v$ lifetime-dominates every object selected by
its ERN set:

$$
x \in ERN_G(v) \land Alive_G(v) \Longrightarrow Alive_G(x)
$$

This is memory-lifetime dominance, not control-flow dominance.

## Cascading deallocation

Removing one owning handle removes exactly one incoming graph edge. At its
EHIR-determined last use, the operation is synchronous: it classifies the ERN
region which became exclusive and logically deletes that complete region as
one transaction.

For $S = ERN_G(v)$:

$$
Deallocate_G(v) : G \longrightarrow G[V \setminus S]
$$

Logical death precedes physical reclamation:

- heap-node storage is returned to the heap allocator;
- a stack node is marked logically dead, while its bytes are reclaimed by slot
  reuse or by leaving its frame.

The ERN definition guarantees that no owning edge enters the deleted set from
a survivor:

$$
x \in S \land (u \rightarrow x) \in E \Longrightarrow u \in S
$$

Therefore no surviving safe EHIR reference points into deleted storage. This
is the central use-after-free safety property.

### Runtime algorithm

The implementation may use reference counts as an index into the graph
algorithm, but ordinary reference counting is not the semantic model and may
not leak cycles.

The required implementation is:

1. Remove the released incoming edge.
2. Use a zero-count work queue as the fast path for acyclic regions.
3. For a possible cycle, collect $P_G(v)$ iteratively.
4. For each candidate node compute `trial = refcount - internal_in_degree`.
5. Mark nodes with a positive trial count as externally reachable and
   propagate that mark through their outgoing edges.
6. Treat the remaining nodes as one ERN transaction.
7. Detach edges to survivors, mark the ERN nodes dead, then run shallow
   finalization and physical reclamation.

Safe graph mutation, retain and ERN classification share one graph lock so the
proof observes one snapshot. Shallow finalization runs after the lock is
released. User code cannot resurrect a logically dead node.

## Stack placement

A stack node belongs to a specific frame $f$ and is valid only when:

$$
Storage(v) = Stack(f) \Longrightarrow Lifetime(v) \subseteq Lifetime(f)
$$

The EHIR validator rejects a stack node which can escape through:

- a return from its owning frame;
- a heap or global field which can outlive the frame;
- `spawn` or another thread boundary;
- a coroutine suspension point whose frame does not own the node;
- a native call without a verified non-escaping contract.

Passing `T<S>` to a known non-escaping `T&` parameter is valid. Returning a
fresh `T<S>` from the frame which allocated it is not.

Stack allocation sites use lifetime regions and slot reuse. A construction in
a loop is accepted when an instance dies before the next iteration, or when a
finite maximum number of overlapping instances is proven. The compiler reports
an error rather than silently using the heap for an unbounded overlap.

## Ownership at function boundaries

Function parameters, locals, fields, container elements, globals and native
pins are graph roots or edges while they exist. Canonical EHIR uses these
rules:

- copying a node handle creates one new owner;
- a call parameter owns its incoming handle;
- a return transfers one live owner to the caller;
- a phi transfers the owner selected on its incoming control-flow edge;
- reading a node-handle field creates a new owner unless the field is moved;
- leaving a path drops every live owner not transferred elsewhere.

The ownership pass may replace an acquire followed by a release with a move
when liveness proves there is no interval containing both owners. This is an
optimization of the physical operations, not a different abstract model.

Arguments are evaluated from left to right. All argument values are
materialized before last-use transfers are committed, so passing one handle in
several arguments produces the required number of owners independently of
argument order.

## Field and element replacement

Replacing storage which contains owning handles is transactional:

1. copy or acquire the complete new value;
2. snapshot the old value;
3. install the new value;
4. drop the old value.

This order makes self-assignment safe. It applies recursively to inline
aggregates, node fields and container elements.

Raw `load` and `store` are bit operations and never infer ownership. Trusted
container/runtime code uses ownership-aware load, initialization, replacement
and drop-place EHIR operations instead. The LLVM backend must not decide
ownership from a type name or variable-name suffix.

## Type lifecycle metadata

Every monomorphized payload used as a node has a descriptor which can:

- enumerate all outgoing node-handle edges;
- report whether a cycle is possible;
- perform shallow finalization of non-graph storage.

Structural descriptors for structs, enums, tuples and arrays are synthesized.
Opaque runtime-backed types declare the same lifecycle contract explicitly.
`Vec`, `str`, `Option`, a module path or a test name must never be a backend
ownership special case.

Shallow finalization does not release child graph handles: the ERN transaction
has already classified and detached those edges. Arbitrary user destructors and
resurrection are not part of this model.

## Strings, enums and dynamic values

`str` keeps its ordinary surface spelling and immutable value behavior. Its
storage is backed by the common heap-node runtime and copying a string value
creates another owning handle to that storage.

Enums, including `Option[T]` and `Result[T, E]`, are inline tagged values by
default. Their payload is stored inline and follows the recursive copy/drop
rules. An enum becomes a node only when written with `<S>`, `<H>` or `&`.

A dynamic trait value contains a node handle plus its vtable identity. Casting
an inline aggregate to `dyn Trait` first places that value in a heap node;
casting an existing node handle retains the same node.

## Mutable collections

Mutable collections are normal graph nodes rather than backend-specific
reference-counted buffers. For example, the public vector API uses
`Vec[T]<H>` and `Self&` receivers. Its descriptor enumerates node handles
contained recursively in every initialized element.

```enq
let mut values = Vec[Target<H>]::new()
values.push(Target<H>{1_u32})
let same = values
// values and same refer to the same vector node; same is read-only.
```

`values.clone()` is the library operation for an independent vector.

## Concurrency

Ordinary spawn arguments must have a recursively transfer-safe inline shape.
Public node handles cannot cross that boundary merely because they are owned.
Exclusive graph regions can instead cross through `sending`; recursively
read-only shared regions use `frozen`. These are compiler-checked capabilities,
not an opt-in nominal `Send` trait. See [Concurrency](concurrency.md).

Runtime-internal immutable nodes, such as string storage, may cross threads.
The common graph lock and atomic publication rules keep their ownership
metadata safe without exposing shared mutable node payloads to Encore code.

## Native boundaries

Every native signature declares whether an input is an inline value, node
handle or raw pointer. A native function receiving an owning handle gets one
owner for the call. It cannot retain that handle beyond the call without an
explicit transfer contract.

An extern `T&` parameter accepts a stack node only when declared `noescape`.
Raw pointers are allowed only through `unsafe`; native pins which keep a node
alive must be represented as roots visible to the graph runtime.

## Compiler invariants

The following properties are mandatory:

1. `T`, `T<S>`, `T<H>`, `T&` and `T*` remain distinct through EHIR validation.
2. `T&` is an owning node handle, never a raw pointer or borrow.
3. `mut` is eliminated by SSA construction and never selects node placement.
4. Canonical functions have one entry and one normal exit.
5. Every ownership creation, transfer, replacement and last use is handled by
   the general EHIR ownership pass.
6. Stack placement is proven not to escape.
7. `cfree` selects precisely the ERN region, including cycles.
8. The LLVM backend only lowers explicit, validated EHIR semantics.
9. Containers and runtime-backed values describe ownership through lifecycle
   metadata, not backend name checks.
10. Safe raw-memory operations cannot silently copy or destroy owning values.

## Validation and debugging

Memory regressions should state the graph explicitly: roots, node edges, the
released edge and the expected ERN set. Tests must cover both a fully exclusive
region and a shared descendant which must survive.

Use:

- `--trace-cfree` to record the selected ERN nodes and reclamation order;
- Valgrind for invalid native memory access and leaks;
- generated-EHIR assertions for ownership and single-exit form;
- long-running real applications to exercise repeated graph transformations.

A passing type check or LLVM build alone is not proof of memory correctness.
