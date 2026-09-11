# Traits and Dynamic Dispatch

Traits define behavior contracts. Generic trait bounds use static dispatch;
`dyn Trait` explicitly creates a trait object for heterogeneous values and
dynamic dispatch.

```encore
{{#include ../../examples/guide/src/features/mod.enq:traits}}
```

Object-safety diagnostics reject trait methods that cannot be represented by
a dynamic vtable contract.

## Static or dynamic?

A generic bound allows the compiler to choose a concrete implementation for
each instantiation. A `dyn Area` parameter accepts a runtime-selected
implementation behind the trait contract. It is appropriate for heterogeneous
values; it is not required merely to call a method.

Implementations must match the trait's parameter types, return types, generic
shape, and async/capability contracts. A read-only method cannot be implemented
by a mutating receiver. Sending/frozen contracts must also be preserved.
Changing an implementation cannot silently weaken caller guarantees.

When a dynamic conversion fails, check the declaration's object safety and
the implementation signature, not only the method name. Start with a small
trait; keep operations needing a concrete type outside its dynamic interface.
See [API design](../designing-programs.md) for choosing enum versus trait.
