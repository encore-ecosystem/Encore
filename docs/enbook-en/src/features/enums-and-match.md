# Enums and Pattern Matching

Enum variants may be unit-like or carry fields. `match` destructures the
selected variant, and semantic checking requires exhaustive, non-duplicated
coverage.

```encore
{{#include ../../examples/guide/src/features/mod.enq:enums}}
```

In the example, `Quit` has no payload and `Value` carries a `u32`. The binding
inside a match arm is available in that arm, not after the match. A generic
enum such as `Option[T]` uses the same model. Arms of a match expression must
produce compatible result types.

Use explicit enum arms when adding a variant should make callers revisit their
logic. A wildcard `_` is useful for a fallback over literal inputs, but can
hide an unhandled new case. Do not use a duplicated arm as an override; it is
not a second chance to match the same variant.

See [construct examples](../language-construct-examples.md#enums-and-patterns)
for literal and payload shapes. Conditions inside an arm are ordinary control
flow; do not assume pattern-guard syntax from another language is available.
