# Loops, Ranges, and Labels

Use `for value in start..end` for an exclusive range and `..=` for an
inclusive one. `while`, `do ... while`, and `loop` cover condition-driven and
unbounded iteration. Labels let `break` and `continue` target an outer loop.

```encore
{{#include ../../examples/guide/src/features/mod.enq:loops}}
```

The sample's exclusive upper bound makes `sum(4)` add 0, 1, 2, and 3. An
inclusive range also visits its endpoint. A `while` body may execute zero
times; a `do ... while` body executes before its condition is checked.
`break` leaves its target loop, while `continue` advances that loop's control
flow. A label distinguishes the intended loop in nested traversal.

For collections, `for` uses the iterator protocol rather than promising indexed
access. Avoid mutating an iterated collection unless that iterator's API
explicitly supports it. For manual indices, check bounds before access and
consider empty input and the largest valid endpoint.

**Exercise:** what does `sum(0)` return? Zero: the exclusive range is empty.
Turning every `..` into `..=` would change that boundary behavior.
