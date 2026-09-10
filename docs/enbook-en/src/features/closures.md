# Closures

Closures use `|arguments| expression` or `|arguments| { ... }`. Captured
values become closure environment fields. A closure can satisfy a compatible
trait object when its call shape matches the trait's method.

```encore
{{#include ../../examples/guide/src/features/mod.enq:closures}}
```

The compiler rejects a closure whose captured stack references escape their
valid lifetime.

In this fragment the `Handler` return type supplies the argument/result shape,
and `base` is captured. Creating the closure is not calling it. The closure
environment must obey the same ownership rules as other values; captures do
not make stack nodes heap-safe or grant write access to read-only data.

Prefer a named function when it needs no local state and the name explains
its purpose. Use a closure for small behavior coupled to local values. When
inference fails, provide the expected callable/trait shape rather than adding
unrelated casts. A native thread entrypoint is a separate contract: do not
assume every closure can be passed to `spawn`.
