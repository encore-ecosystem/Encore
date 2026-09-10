# Tuples, Arrays, and Vectors

Tuples combine heterogeneous values, arrays have fixed length, and `Vec[T]`
is a growable homogeneous collection. Indexing an array returns its element;
`Vec.get` returns `Option[T]` so bounds failure is explicit.

```encore
{{#include ../../examples/guide/src/features/mod.enq:collections}}
```

Use a tuple for a small group whose positions have a clear meaning; use a
struct when named fields communicate that meaning better. An array's length
is part of its type. Choose a vector when the size changes at runtime.

Tuple positions use `.0`, `.1`, and so on. Arrays use `[index]`. A vector's
`get` makes absence explicit: handle `Some`/`None` or choose an intentional
default with `unwrap_or`. Do not assume the same bounds-failure API for every
collection.

Construct an empty vector with an element type, such as `Vec[u32]::new()`.
Without elements or expected-type context, there may be nothing from which to
infer it. Mutating calls require a mutable capability. Copying a vector handle
shares its node; see [values and sharing](../values-and-sharing.md) before
assuming assignment duplicates the elements.
