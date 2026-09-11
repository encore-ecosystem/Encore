# Methods and Receivers

`impl for Type` adds inherent methods. The `self` parameter states receiver
ownership and `self: mut Self` authorizes mutation. Methods can return `Self` for
builder-style APIs.

```encore
{{#include ../../examples/guide/src/features/mod.enq:methods}}
```

`current` reads; `increment` requests a mutable receiver. The caller must
provide a mutable path. A method that returns `Self` may instead implement a
value-transforming builder: keep its returned value rather than assuming
that a discarded result updated the original.

For node payload mutation, use an appropriate node receiver such as
`self: mut Self&`. `&` does not itself mean mutable. Choose inline versus node
representation first, then the receiver capability. See
[values and sharing](../values-and-sharing.md).

**Exercise:** a `len` method only reads collection state. Should it request
`mut`? No: doing so needlessly prevents calls from read-only paths.
