# Unsafe Code and Embedded EHIR

`unsafe` marks operations whose invariants cannot be proven by ordinary
Encore checking, including native extern calls. Keep unsafe blocks small and
document the caller-visible invariant.

```encore
{{#include ../../examples/guide/src/features/mod.enq:unsafe}}
```

`ehir { ... }` and `unsafe ehir { ... }` embed EHIR instructions for compiler
and systems work. EHIR is an independent compiler IR and abstract machine;
Encore is one high-level frontend that lowers into it.

## Native calls need an ABI contract

An `extern fn` declares a symbol; it does not implement that symbol or arrange
for a library to be linked. The clock fragment above relies on the matching
Encore platform runtime. It is not a portable declaration of an arbitrary
system C function. Configure native sources and libraries through
[build metadata](../packages.md#native-build-scripts).

Match argument/result representation, calling convention, target integer
widths, and ownership expectations on both sides. `str` is not a C
NUL-terminated `char*`. A `T&` is an owning graph handle, not a C pointer to an
inline payload. Do not "fix" a native signature by casting until it compiles.

For raw pointers, establish who allocates and frees storage, how long it stays
valid, its alignment and bounds, and whether another thread may access it.
For stack handles, prove the callee cannot retain or return an escaping handle.
An `unsafe` block records where a proof is required; it does not manufacture
that proof or disable all language checking.

Keep the native declaration private and expose a small safe wrapper only when
the wrapper can enforce its documented preconditions. Test that wrapper on
each supported ABI. Embedded EHIR is an advanced implementation tool, not the
first remedy for a missing high-level API.
