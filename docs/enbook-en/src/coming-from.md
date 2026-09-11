# Coming from Another Language

Use familiar concepts as starting points, not as promises of identical behavior.
The main tutorial does not assume any particular previous language.

## From Rust or C++

- `Point` is an inline payload, while `Point<H>` explicitly names a heap
  node. `Point&` is an **owning node handle**, not a Rust borrow or C++ reference.
- Generic arguments use `[T]`. Angle brackets are used for node placement.
- `mut` is a deep path capability. Ordinary receivers are read-only;
  ownership of a handle alone does not authorize mutation.
- Graph-memory cleanup handles reachability and cycles. Do not map it blindly
  to `Rc`, `shared_ptr`, tracing GC, or user-defined RAII destructors.
- Use `with` and the resource API's documented contract for protocol cleanup.
- Thread-region contracts use `sending` and `frozen`; do not assume adding
  a nominal `Send` implementation permits arbitrary shared mutation.
- `ret` is explicit return. Match arms use `=>`, and generic `impl` syntax
  is described in [traits](features/traits-and-dyn.md).

## From Python or TypeScript

- Variables are statically typed, even when a local annotation is inferred.
  An integer literal fitting one type does not make all numeric conversions safe.
- Inline aggregate copying and node sharing are different operations.
  Learn [values and sharing](values-and-sharing.md) before relying on aliasing.
- `Result` makes recoverable failure visible in a signature; postfix `?`
  propagates an error, not an optional property lookup.
- An enum lists alternatives explicitly. Exhaustive matching prevents forgetting
  a case; it is more than a string-valued convention.
- Decorators are compile-time wrappers, not arbitrary runtime reflection.
  Macros expand syntax; they are not dynamic function calls.
- Calling an async function does not start a native thread. `spawn` is explicit.

## Keep your first port small

Port a pure function and its edge-case tests before the entire application.
Then add I/O, package boundaries, and concurrency independently. Avoid
translating every class, decorator, exception, or pointer one-for-one.

**Exercise:** a Python assignment shares a list. Does assigning an Encore
struct necessarily share all its data?

<details><summary>Answer</summary>

No. The struct's inline payload is copied. Node handles inside the payload
still share their nodes. Distinguish the outer value from the graph it reaches.

</details>
