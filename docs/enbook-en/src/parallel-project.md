# Project: Parallel Work

Now process two independent batches concurrently. Read [values and
sharing](values-and-sharing.md) first; use [Concurrency](concurrency.md) as the
reference for `sending` and `frozen`.

## Transfer independent work

The following is a program fragment. Put it below
`import core::vec::Vec` in `src/main.enq` of a fresh project:

```encore
{{#include ../examples/guide/src/tutorial/mod.enq:parallel}}
```

Add this entrypoint to complete the program:

```encore
fn main() -> u32 {
    ret if parallel_total() == 100_u64 { 0_u32 } else { 1_u32 }
}
```

Run `encore run`. Successful execution has no output and exit status zero.
The same computation is checked by the book's `book_parallel_result` unit test.

`sending` transfers each exclusive vector region to its worker. There are no
shared mutable counters or locks. Cast each input to `u64` before accumulating,
so adding several `u32` inputs does not immediately overflow a `u32` sum.
This does not make an arbitrarily large `u64` sum overflow-proof.

Both workers start before either join. Replacing this with spawn/join followed
by spawn/join serializes the batches. Results are combined in a predictable
order; console messages printed by workers would not have a guaranteed order.

## What must not compile

After spawning, attempting to inspect the transferred vector is invalid. A
live alias also prevents proving exclusive transfer. For shared read-only work,
use `frozen`, not a mutable alias disguised as an ordinary parameter. See the
negative examples and diagnostics in [Concurrency](concurrency.md).

## Scale only after measuring

Two tiny batches illustrate ownership, not a speedup. Native thread startup
can cost more than the arithmetic. For large inputs, bound worker count using
`std::thread::available_parallelism()`, partition into nonoverlapping batches,
and compare with a sequential implementation on identical input. Do not spawn
one OS thread per element.

`async` does not change this CPU-parallel algorithm into a faster one. Awaiting
a future suspends cooperative work; it does not itself allocate an OS thread.

**Exercise:** one batch is empty. What should change in the result and program?

<details><summary>Answer</summary>

An empty batch contributes zero. The worker still terminates and is joined.
Test that case before generalizing to dynamically partitioned input; otherwise
zero-length partitions can hide incorrect loop bounds.

</details>
