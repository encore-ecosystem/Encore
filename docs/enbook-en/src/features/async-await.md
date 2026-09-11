# Async and Await

`async fn` returns a concrete state-machine type implementing `Future[T]`.
`await` suspends that state machine without blocking its executor thread.
`std::future::block_on` drives a future to completion at a synchronous edge.

```encore
{{#include ../../examples/guide/src/features/mod.enq:async}}
```

The generated `__encore_future_async_increment` name in this low-level example
is compiler-specific. Prefer inferred generic arguments where accepted and do
not expose generated future names as a stable library API.

Creating a future does not run it on another CPU. An executor polls it;
`await` yields when the operation is pending. Blocking I/O inside an async
function can still block its executor thread. Separate CPU-parallel work with
native threads when appropriate, rather than adding `async` to every function.

Suspension preserves live state, so values kept across an await must satisfy
the memory model's lifetime restrictions. Read [Concurrency](../concurrency.md)
for the distinction between cooperative work and OS-thread transfer.
