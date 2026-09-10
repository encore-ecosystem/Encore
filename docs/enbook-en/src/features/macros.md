# Declarative Macros

`macro_rules!` transforms syntax at compile time. Arms match token fragments
such as `expr` and `ident`, then substitute them into a template. Macro calls
end with `!`.

```encore
{{#include ../../examples/guide/src/features/mod.enq:macros}}
```

## Choose a macro for syntax

Prefer a normal or generic function when arguments and results are ordinary
values. Use a macro when the call needs to accept or produce syntax a function
cannot express. Fragment kinds such as `expr` and `ident` constrain the input;
repetition forms match repeated input fragments. An unmatched invocation is a
compile-time problem, not a runtime dispatch fallback.

Count uses of each captured expression in the expansion. If a template inserts
an expression twice, side effects in that expression can occur twice. A
function parameter normally evaluates its argument once. Avoid introducing
macros merely to save a function call that the optimizer can inline.

When debugging, reduce the invocation to one matching arm and check the code
it expands to. The `add_one!` example inserts its expression once. Compare it
with a hypothetical `($value + $value)`: that is not a safe general-purpose
replacement for binding an evaluated value and then adding it to itself.
