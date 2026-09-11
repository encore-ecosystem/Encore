# Values, Sharing, and Mutation

Before learning the formal memory model, answer two practical questions:
**did I copy data or share a node, and may this path modify it?** These are
different questions in Encore.

## Inline does not mean shared

An inline struct stores its fields as a value. Copying it copies its payload.
A node handle instead owns an edge to separately placed storage:

```text
inline copy:   first [x, y]       second [x, y]
handle copy:  first ──┐
                     ├──> one node [x, y]
              second ┘
```

| Form | What it denotes | Typical reason to use it |
| --- | --- | --- |
| `Point` | inline payload | small independent data |
| `Point<S>` | owning stack-node handle | bounded lifetime with proven non-escape |
| `Point<H>` | owning heap-node handle | shared node or lifetime beyond this frame |
| `Point&` | owning node handle with erased placement | accept either safe placement |
| `Point*` | raw address | unsafe native boundary |

Unlike Rust's `&T`, Encore's `T&` is **not a borrow**. Unlike a C pointer, it
participates in graph ownership. Neither syntax grants mutation by itself.

## Mutation is an API contract

Declare `let mut` when a local needs to change, and `self: mut Self` or a
`mut` parameter when a function changes data through that input. An ordinary
receiver is read-only, including its fields. Returning a new value is another
useful API: the caller explicitly assigns the result.

Do not turn an immutable alias into a writer with a second `let mut`. Choose
the mutable capability at construction, pass it through an explicit mutating
API, or construct an independent copy using the type's copy/clone API.

See [methods](features/methods.md) for an example of the contract and
[concurrency](concurrency.md) for stronger `sending` and `frozen` contracts.

## Collections and nested data

A vector constructor produces a node. Copying a vector handle does not make an
independent vector. An inline struct containing that handle copies the handle,
so the two outer values still share that nested collection. Use `clone` when
you need independent collection storage; do not assume it recursively duplicates
every nested node. The element type's copying rules still matter.

**Exercise:** two inline records each contain a number and a handle to the same
vector. Which parts are independent?

<details><summary>Answer</summary>

The numeric fields and outer payloads are independent. The vector node is
shared. Neither sharing nor an extra immutable alias authorizes mutation.

</details>

## Lifetime and cleanup

Safe stack nodes cannot escape their allocating frame. A heap node remains
alive while reachable through owning roots. Graph cleanup handles cycles; it
is not ordinary reference counting that necessarily leaks every cycle. Do not
infer that cleanup is free or that collection storage is contiguous with its
owner.

Resources such as sockets also have protocol-level lifetimes. Use their close
API or [context manager](features/context-managers.md) contract rather than
treating graph-memory reclamation as an arbitrary user destructor mechanism.

Read [Memory Model and ERN](memory-model.md) for the exact ownership rules,
stack escape restrictions, lifecycle metadata, and cleanup algorithm.
