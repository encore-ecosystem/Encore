# Strings and F-Strings

`str` is the built-in string value. Prefix a literal with `f` to interpolate
expressions directly. `{name}` uses a visible binding and `{expression}`
evaluates an expression once at the interpolation point.

```encore
{{#include ../../examples/guide/src/features/mod.enq:strings}}
```

Use `std::string::String` when its convenience methods are useful. It wraps
`str`; do not infer Rust's borrowed `str` versus owned `String` distinction.

## Bytes are not characters

For `let text = "é"`, `text.byte_len()` is 2 and `text.char_len()` is 1.
The `String` wrapper's `len()` counts scalar values and `byte_len()` counts
bytes. Prefer explicit unit names in algorithms rather than assuming all
length methods use the same unit. A scalar value is still not necessarily a
user-perceived grapheme: combining marks can make one displayed letter from
several scalars.

Use `get(index)` for optional scalar access and `get_byte_at(index)` for
optional byte access on `str`. The wrapper exposes `char_at` and `byte_at`,
both returning `Option`. `slice(start, length)` is character-oriented;
`slice_bytes` is byte-oriented. The second argument is a **length**, not an
exclusive end index. Do not split UTF-8 at arbitrary byte offsets.

`String::push_str` returns a new wrapper; assign the result if you intend to
keep it. It is not an in-place mutation merely because its name starts with
`push`. Repeated concatenation in a loop can repeatedly allocate; measure it
before using it for large text processing.

The [text-report project](../text-report.md) deliberately scans ASCII delimiter
bytes and documents why that does not implement Unicode word segmentation.
