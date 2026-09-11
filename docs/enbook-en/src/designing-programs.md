# Designing APIs and Handling Errors

Once a program works, make its choices visible in types. This chapter assumes
functions, structs, enums, and the [values model](values-and-sharing.md).

## Choose the smallest abstraction

| Need | Start with | Why |
| --- | --- | --- |
| several known alternatives | enum and `match` | callers must handle the alternatives |
| same algorithm for different types | generic function and bounds | concrete specialization, explicit requirements |
| heterogeneous implementations chosen at runtime | `dyn Trait` | runtime dispatch behind one contract |
| state plus helper behavior | struct and inherent methods | no interface abstraction required |

A trait is useful at a real boundary, not merely because another language
would introduce a class hierarchy. Prefer composing fields and functions.
Avoid exposing a concrete storage choice when callers only need an operation.

## Separate absence from failure

`Option[T]` represents an absent value, such as a missing optional argument.
`Result[T, E]` represents an operation that can fail with an explanation. An
empty string, zero, and an empty collection can all be successful values: do
not use them as invented error sentinels unless the API explicitly does so.

This example is a function fragment, with imports included:

```encore
{{#include ../examples/guide/src/features/mod.enq:result}}
```

It needs `import core::result::Result`. `?` unwraps `Ok` or returns `Err` from
the current function. It does not log, retry, panic, or continue the loop.
Handle the error at a boundary that can decide what to do: the CLI can print
it and return a nonzero exit code, while a library should preserve useful
information for its caller.

An enum error type is appropriate when callers need to distinguish cases.
A string error is sufficient for a small tutorial. Panic is not a substitute
for a recoverable invalid user input. Conversely, catching every failure and
returning a default can make corrupted output look successful.

## Organize modules around responsibilities

Put reusable computation in a module and keep filesystem/terminal work in the
entrypoint. Export only the API that other modules need with `pub`. Within
your package, `refrain::stats` refers to its `src/stats/mod.enq`; importing an
external refrain also requires declaring its dependency in `encore.toml`.

Write `//!` documentation for the module and `///` for public declarations.
Document units, mutation, failure cases, and platform requirements. These
comments help both book readers and LSP hover users.

## Test the boundary, not just the happy path

Test empty input, one item, invalid input, and a representative ordinary case.
Keep pure functions testable without a display server or network connection.
Use `#attr(test)` functions returning `bool`; run a focused selection with
`encore test --filter name` while working.

**Exercise:** should a lookup with an optional missing key return `Option`,
`Result`, or panic?

<details><summary>Answer</summary>

Use `Option` if absence is expected and is the only alternative. If lookup can
also fail because an external service is unavailable, expose that separate
failure through `Result`. A missing user-supplied key is not a reason to panic.

</details>
