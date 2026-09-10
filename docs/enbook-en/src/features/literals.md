# Literals

Encore has integer, floating-point, Boolean, and string literals. Numeric
suffixes such as `_u32`, `_usize`, and `_f32` make representation explicit;
otherwise the expected type drives inference.

```encore
{{#include ../../examples/guide/src/features/mod.enq:literals}}
```

## Radix and expected type

The radix changes the spelling of a number, not its type. These are fragments
to put inside a function:

```encore
let bits: u8 = 0b101010
let permissions: u16 = 0o755
let mask: u8 = 0xff
let capacity: u16 = 5000
```

The values are respectively 42, 493, 255, and 5000. An explicit suffix also
works: `0xCAFE_u16`. Type context comes from annotated bindings, function
arguments, returns, and aggregate fields. For `fn reserve(size: u16) -> ()`,
`reserve(5000)` does not need `_u16`. Add an annotation when context cannot
determine the intended type, especially empty generic containers.

`0b102` is invalid syntax; `256` passed to a `u8` parameter is an out-of-range
literal. These are compile-time failures, not truncation. See
[troubleshooting](../troubleshooting.md).

## Conversion is a separate operation

`as` converts an existing numeric value; it does not prove the value fits.
The regression examples cover widening and in-range float-to-integer conversion
(`4.75_f32 as i32` yields 4). Check bounds before narrowing user input. Do not
assume Python-style unbounded integers or Rust-style profile-dependent overflow
checks: this book does not promise a checked arithmetic API or portable behavior
for out-of-range runtime conversions. Keep arithmetic in range and test the
actual target. `usize` width depends on that target.

**Exercise:** why is `0xff` valid for `u8`, but `0x100` is not?

<details><summary>Answer</summary>

They denote 255 and 256. An unsigned eight-bit value has only 256 distinct
values, from zero through 255. Changing the base does not change that range.

</details>
