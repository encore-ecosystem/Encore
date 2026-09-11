# Functions and Generics

Functions declare parameter and result types. Generic parameters are written
in brackets and are monomorphized for concrete uses, so abstraction does not
require dynamic dispatch unless the program asks for `dyn Trait`.

```encore
{{#include ../../examples/guide/src/features/mod.enq:functions}}
```

## Let the call provide context

`identity(42_u32)` specializes `T` as `u32`; `identity[u32](42)` supplies the
type explicitly. Specify types when empty containers or ambiguous calls give
the compiler too little information. Generic parameters describe types, not
dynamic values to inspect at runtime.

A function using a trait-defined operation must declare the required bound
and have the trait visible. An unconstrained `T` is not a promise that every
operation will work for every caller. A missing bound should be fixed in the
contract, not deferred until a particular use accidentally happens to compile.

Use concrete parameter types for concrete APIs. Generic code is useful when
several types genuinely share an algorithm. For runtime-selected heterogeneous
implementations, see [traits](traits-and-dyn.md).
