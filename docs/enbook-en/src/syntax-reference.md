# Syntax Quick Reference

Use this appendix to locate a rule, not as a replacement for its explanation.
The [Language Guide](language-basics.md) and its feature pages show examples.

## Declarations and control flow

| Spelling | Purpose | Read next |
| --- | --- | --- |
| `fn`, `ret`, `->` | function and return | [functions](features/functions-and-generics.md) |
| `let`, `mut`, `static` | binding and capability | [bindings](features/bindings-and-static.md) |
| `struct`, `enum` | product and alternative data | [structs](features/structs-and-placement.md), [enums](features/enums-and-match.md) |
| `trait`, `impl ... for`, `Self`, `dyn` | behavior contracts and dispatch | [traits](features/traits-and-dyn.md) |
| `pub`, `import`, `as`, `::` | visibility, paths, aliases | [imports](features/imports-and-visibility.md) |
| `if`, `elif`, `else`, `match`, `=>` | conditional selection | [conditions](features/conditionals.md) |
| `while`, `loop`, `do`, `for`, `break`, `continue` | iteration and loop control | [loops](features/loops-and-ranges.md) |
| `async`, `await`, `spawn` | cooperative work and native threads | [concurrency](concurrency.md) |
| `sending`, `frozen` | transfer and immutable-region contracts | [concurrency](concurrency.md) |
| `with` | context-managed resource use | [context managers](features/context-managers.md) |
| `extern`, `unsafe`, `ehir` | native and IR boundaries | [unsafe](features/unsafe-and-ehir.md) |
| `macro_rules!`, `name!(...)` | syntactic expansion | [macros](features/macros.md) |
| `#cfg(...)`, `#attr(...)`, `@...` | configuration, attributes, decorators | [attributes](features/attributes-and-cfg.md) |

Some entries are contextual syntax, not globally reserved lexer keywords.
Do not infer that a token's presence alone makes every combination legal.

## Operators: tighter to looser

The current parser groups ordinary expressions in this order:

| Precedence | Operators/forms |
| --- | --- |
| tightest | calls, indexing, field access, postfix `?` |
| unary | `!`, `~`, unary `+`/`-`, `await`, `spawn` |
| cast | `as` |
| power | `**` (right-associative) |
| multiply | `*`, `/`, `%` |
| add | `+`, `-` |
| shifts | `<<`, `>>` |
| ordering | `<`, `<=`, `>`, `>=` |
| equality | `==`, `!=` |
| bitwise AND | `&` |
| bitwise XOR | `^` |
| bitwise OR | `|` |
| logical AND | `&&` |
| loosest | `||` |

Use parentheses when mixing categories, especially masks and comparisons:
`(value & mask) == expected`. Do not read a chain of comparisons as a
mathematical conjunction. Assignment and compound assignments are statement
forms; ranges `..` and `..=` occur in iteration syntax.
See [operators and casts](features/operators-and-casts.md) for examples.

## Types and notation

`[T; N]` is a fixed array; `(A, B)` a tuple; `()` unit; `Type[T]` a
generic application. Type parameters use brackets, not C++/Rust angle brackets.
Angle suffixes `<S>` and `<H>` choose node placement instead. The suffix
`&` erases node placement; `*` is an unsafe raw address.
See [values and sharing](values-and-sharing.md).

`//!...` documents a module; `///...` documents a declaration.
Ordinary `//...` and `/*...*/` comments do not supply hover documentation.
A leading `f` enables string interpolation; `format!` performs formatting.

For numeric prefixes, suffixes, and contextual inference, see
[literals](features/literals.md). For required imports and complete programs,
follow the linked chapter rather than copying an isolated table entry.
