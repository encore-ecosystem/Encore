# Decorators

Mark a wrapper with `#attr(decorator)`, then apply it with `@expression`.
Encore specializes the wrapper around the original function during lowering;
it does not allocate a runtime reflection object or indirect callable.

```encore
{{#include ../../examples/guide/src/features/mod.enq:decorators}}
```

The required leading parameters are the original `Callable` and its packed
arguments. Extra decorator arguments follow them. Multiple decorators nest in
source order, and `@RENDER_PROFILE.profile("draw_frame")` works for methods as
well as free functions.

Choose a decorator when several functions need the same surrounding behavior,
such as profiling. Choose a normal helper when explicit calls make the control
flow clearer. The wrapper's result must match its contract; async wrappers
must preserve the intended await/return behavior.

Treat stacked wrappers as nesting: the outer wrapper enters first and leaves
last. Test order with distinguishable effects rather than assuming wrappers
commute. Adding a retry wrapper around a side-effecting function can repeat
the effect; compile-time specialization does not make that operation harmless.

The sample's manager intentionally returns the original result unchanged. It
demonstrates wiring, not a useful timing implementation. Real profiling should
use a monotonic clock and report its measurement boundaries. See
[development and performance](../development.md).
