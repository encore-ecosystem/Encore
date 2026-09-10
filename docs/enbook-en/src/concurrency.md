# Concurrency

Encore has two complementary concurrency models:

- `spawn` starts an operating-system thread for CPU-parallel or blocking work;
- `async`/`await` suspends cooperative work without creating a thread by itself.

This chapter explains the values that may cross a native-thread boundary and
the capabilities used to transfer or share mutable graph regions safely.

## Spawn and structured join

Apply `spawn` to a direct Encore function call. It moves the call arguments
into a native thread and returns `JoinHandle[T]`:

```enq
fn square(value: u64) -> u64 {
    ret value * value
}

fn main() -> u32 {
    let left = spawn square(12_u64)
    let right = spawn square(15_u64)
    let total = left.join() + right.join()
    ret if total == 369_u64 { 0_u32 } else { 1_u32 }
}
```

`join()` blocks until the thread completes and moves its result back to the
caller. A handle can be joined only once. Dropping an unjoined handle performs
a structured join and drops its result, so a spawned thread cannot outlive the
scope that owns its handle.

Generic functions are valid spawn targets. The compiler monomorphizes both
the function and its native thread trampoline for the concrete type arguments:

```enq
fn identity[T](value: T) -> T {
    ret value
}

let answer = spawn identity[u32](42_u32)
```

Use `std::thread::available_parallelism()` to inspect the number of logical
processors available to the process. Avoid starting an unbounded number of
native threads; partition long-lived work across a bounded worker set.

## What is safe to send

An ordinary spawn argument must be an owned inline value whose complete shape
is safe to move between threads.

| Value shape | Ordinary spawn argument |
| --- | --- |
| numbers, booleans and strings | allowed |
| tuples, arrays, enums and inline structs | allowed when every nested value is safe |
| `T<S>`, `T<H>` and `T&` node handles | rejected |
| `Vec[T]` and other mutable graph regions | rejected unless transferred with `sending` |
| raw pointers, dynamic trait objects and thread handles | rejected |
| mutable local aliases | rejected |

Strings are immutable values backed by runtime-internal synchronized storage,
so copying a string into another thread is safe. This does not make arbitrary
user-visible graph nodes thread-safe.

The recursive check prevents a node handle from being hidden inside an inline
aggregate:

```enq
struct Work {
    id: u64
    // A node-handle field here would make Work non-sendable.
}

fn process(work: Work) -> u64 {
    ret work.id
}

let handle = spawn process(Work{7_u64})
```

## Exclusive transfer with `sending`

Use a `sending` parameter to move an exclusively owned mutable region into a
call or spawned thread:

```enq
import core::vec::Vec

fn count(values: sending Vec[str]) -> usize {
    ret values.len()
}

fn main() -> u32 {
    let mut values = Vec[str]::new()
    values.push("alpha")
    values.push("beta")

    let worker = spawn count(values)
    // values is consumed and cannot be used here.
    ret worker.join() as u32
}
```

The compiler proves that no other live alias or unknown graph connection can
reach the transferred region. The source path is consumed even for a normal
call; `sending` is an ownership contract, not syntax specific to `spawn`.

A function may construct and return an exclusive region:

```enq
fn make_values() -> sending Vec[str] {
    let mut values = Vec[str]::new()
    values.push("ready")
    ret values
}
```

Sending fails when a live alias remains:

```enq
let values = Vec[str]::new()
let alias = values
// spawn count(values) // error: live aliases reach the region
```

It also fails when the region has been connected to another graph whose
reachability is not exclusively represented by the source path.

## Shared snapshots with `frozen`

Use `frozen` when several workers need the same recursively read-only graph:

```enq
import core::vec::Vec

fn inspect(values: frozen Vec[str]) -> usize {
    ret values.len()
}

fn main() -> u32 {
    let mut values = Vec[str]::new()
    values.push("ready")

    let left = spawn inspect(values)
    let right = spawn inspect(values)
    ret (left.join() + right.join()) as u32
}
```

The first frozen use permanently freezes every tracked alias of the region.
Further frozen calls are allowed, but mutation and escape through an ordinary
mutable API are rejected:

```enq
let mut values = Vec[str]::new()
values.push("before")
let worker = spawn inspect(values)
// values.push("after") // error: frozen-region-mutation
```

Freezing is recursive. Fields, elements, pattern-bound values and method
results remain part of the same immutable region. Reading `Vec[Vec[str]]`
therefore cannot recover a mutable inner vector.

A function can publish a newly created snapshot:

```enq
fn snapshot() -> frozen Vec[str] {
    let mut values = Vec[str]::new()
    values.push("ready")
    ret values
}
```

The returned root must already be frozen or exclusively owned. Returning an
ordinary input alias as frozen is rejected because the caller may retain
another mutable path to the same graph.

## Mutation and method receivers

`mut` is a deep path capability. A function or method must request it whenever
it mutates through a parameter or receiver:

```enq
import core::vec::Vec

struct State {
    values: Vec[str]
}

impl for State {
    fn add(self: mut State, value: str) -> () {
        self.values.push(value)
    }

    fn len(self: State) -> usize {
        ret self.values.len()
    }
}

let mut state = State{Vec[str]::new()}
state.add("ready")
```

An ordinary `self` is read-only, recursively. It is not enough that a method
owns a node handle: mutation requires `self: mut T`. No public attribute is
needed to declare this effect.

Trait method capabilities are part of the contract. An implementation must
match `mut`, `sending`, `frozen`, and frozen/sending return capabilities, so
dynamic dispatch cannot replace a read-only or transfer-safe declaration with
a mutating implementation.

## Worker-owned state pattern

The fastest synchronization is often no shared mutation at all. Move one
exclusive state region into each long-lived worker and communicate immutable
inputs or owned results:

```enq
import core::vec::Vec

fn worker(items: sending Vec[str]) -> usize {
    // This thread now owns the region exclusively.
    ret items.len()
}

let mut left_items = Vec[str]::new()
left_items.push("left")
let mut right_items = Vec[str]::new()
right_items.push("right")

let left = spawn worker(left_items)
let right = spawn worker(right_items)
let total = left.join() + right.join()
```

Servers can apply the same pattern by giving each worker its own listener,
reactor, connection set and mutable application state while sharing only
frozen configuration.

## Threads, async work, and blocking

Native threads and async tasks solve different problems:

- use a bounded native worker set for CPU parallelism, blocking system calls,
  or independently owned reactors;
- use `async`/`await` for many cooperatively scheduled operations inside one
  worker;
- do not assume that calling an async function makes it run on another core;
- do not hold mutable aliases across a thread boundary.

An async function may still be called by a native worker. The worker owns the
executor/reactor state, while futures remain lightweight state machines within
that thread.

## Diagnostics

Common diagnostics describe the violated capability rather than a nominal
`Send` trait:

- `thread-transfer-requires-sending`: a mutable region crossed `spawn` through
  an ordinary parameter;
- `sending-path-required` or a live-alias diagnostic: exclusive ownership
  could not be proven;
- `frozen-region-mutation`: code attempted to mutate a frozen projection;
- `frozen-region-escape`: a frozen value was passed to an API that does not
  preserve immutability;
- `mutable-path-required` or `mutable-receiver-required`: mutation was
  attempted without a deep `mut` capability;
- trait capability mismatch: an implementation weakens its trait contract.

Fix the ownership shape rather than hiding it behind `unsafe`: clone an
independent region, transfer the exclusive root with `sending`, share it with
`frozen`, or keep the mutable state local to one worker.

## Runtime guarantee

Runtime-internal immutable graph storage, including string storage, may be
shared across threads. Retain, release, graph-edge mutation and synchronous
ERN classification use the common graph synchronization protocol. User-visible
mutable node payloads remain non-sendable unless their exclusive region is
transferred.

Raw pointers are outside this guarantee. They are accepted only through
`unsafe`, and the programmer must provide the missing lifetime and
synchronization proof.
