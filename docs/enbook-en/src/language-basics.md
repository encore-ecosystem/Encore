# Language Basics

This is a compact reference. Unless labelled as a complete executable, snippets
are fragments requiring the indicated types/imports and a surrounding function.
For a sequential, runnable lesson start with [A Text Report](text-report.md).

Encore source files use the `.enq` extension. Executable packages start from:

```enq
fn main() -> u32 {
    ret 0_u32
}
```

## Imports

Import one item:

```enq
import std::io::println
```

Import a module alias:

```enq
import core::option::Option as Opt
```

Import grouped items:

```enq
import std::{
    fmt::Debug,
    io::println,
    option::Option,
    vec::Vec,
}
```

Import all public items from a module:

```enq
import core::testing::*
```

Trait bounds are checked against traits visible to the module. For APIs with
explicit bounds, import the trait as well as the type:

```enq
import std::dict::{Dict, Hashable}
```

## Documentation Comments

Use `//!` at the beginning of a source file to document its module. Use `///`
immediately before a declaration to document that declaration:

```enq
//! Synchronous and asynchronous networking primitives.

/// Opens a connection to an endpoint.
///
/// # Errors
/// Returns an error when the endpoint cannot be reached.
pub fn connect(endpoint: Endpoint) -> Result[Connection, IoError] {
    // ...
}
```

Consecutive documentation comments are joined with newlines. An empty `///`
line starts a new paragraph. Declaration documentation is available to the
compiler analysis API, EHIR module metadata and language-server hover,
including hover for symbols reached through imports. Ordinary `//` and
`/* ... */` comments are not documentation.

Use the shared tooling database without compiling the project:

```sh
encore check
encore lint
encore lint src/net/mod.enq
encore lint --deny missing-public-docstring
encore lint --format json
encore format --check
encore format
```

`check` reports parser, declaration and type diagnostics without generating
EHIR, object files or a `target` directory. `format --check` reports formatting
drift without writing files; plain `format` applies the deterministic style.

Most lint rules default to warnings. `missing-public-docstring` is disabled by
default so applications are not forced to document every exported
implementation detail; enable it explicitly for library-quality API policy.
Configure persistent levels in `encore.toml`; command-line levels take
precedence:

```toml
[lint.rules]
all = "warn"
missing-module-docstring = "allow"
missing-public-docstring = "deny"
```

`allow` disables a rule, `warn` reports it without failing the command, and
`deny` reports an error and makes `encore lint` return exit status 1. The same
analysis and formatting queries supply compiler and LSP behavior, so diagnostic
codes and formatting do not diverge between the command line and editors.
`encore analyze` remains a deprecated compatibility alias for `encore lint`
and prints a warning on every invocation.

## Values And Mutability

Use `let` for immutable bindings and `let mut` for mutable bindings:

```enq
let name = "encore"
let mut count = 0_usize
count = count + 1_usize
```

Numeric literals can carry suffixes:

```enq
1_u8
1_u32
1_u64
1_usize
-3_i32
1.5_f32
```

Use `as` for numeric casts:

```enq
let wide = 7_u32 as u64
```

## Functions

Functions use explicit parameter and return types:

```enq
fn add(lhs: u32, rhs: u32) -> u32 {
    ret lhs + rhs
}
```

Generic functions put type parameters after the name:

```enq
fn first_or[T](value: Option[T], fallback: T) -> T {
    ret value.unwrap_or(fallback)
}
```

## Unit Tests

Use `#attr(test)` to mark a function as a unit test:

```enq
import core::vec::Vec

#attr(test)
fn vec_len_is_zero() -> bool {
    let v = Vec[u32]::new()
    ret v.len() == 0_usize
}
```

The compiler expects unit tests to return `bool`, take no parameters and avoid
generic parameters. `true` means pass, `false` means fail.

## Structs And Methods

Struct fields are listed by name and type:

```enq
struct Counter {
    value: usize
}
```

Methods are written in `impl` blocks. `Self` is available in method signatures.

```enq
impl for Counter {
    pub fn new(value: usize) -> Self {
        ret Self{value}
    }

    pub fn inc(mut self) -> Self {
        self.value = self.value + 1_usize
        ret self
    }

    pub fn get(self) -> usize {
        ret self.value
    }
}
```

Methods can be called with dot syntax or as associated functions:

```enq
let counter = Counter::new(0_usize).inc()
let next = Counter::inc(counter)
```

## Enums And Match

Enums can have unit variants or payload variants:

```enq
enum MaybeNumber {
    Some(u32)
    None
}
```

Use `match` for enum control flow:

```enq
fn unwrap_or_zero(value: Option[u32]) -> u32 {
    match value {
        Option[u32]::Some(inner) => {
            ret inner
        }
        Option[u32]::None => {
            ret 0_u32
        }
    }
}
```

The compiler rejects duplicate enum arms and non-exhaustive matches in ordinary
checked code.

## Loops

`while` loops:

```enq
let mut i = 0_usize
while i < 10_usize {
    i = i + 1_usize
}
```

Infinite loops with `break`:

```enq
loop {
    if done {
        break
    }
}
```

`for` loops use `IntoIterator`:

```enq
let values = vec![1_u32, 2_u32, 3_u32]
let mut total = 0_u32
for value in values {
    total = total + value
}
```

Ranges:

```enq
for i in 0_usize..10_usize {
    total = total + i
}

for i in 0_usize..=10_usize {
    total = total + i
}
```

Labels can target nested loops:

```enq
'outer: loop {
    loop {
        break 'outer
    }
}
```

## Traits

Declare traits with required methods:

```enq
trait Score {
    fn score(self: Self) -> usize
}
```

Implement a trait for concrete types:

```enq
struct Fixed {
    value: usize
}

impl Score for Fixed {
    fn score(self: Fixed) -> usize {
        ret self.value
    }
}
```

Trait bounds use `T:Trait` and can be combined:

```enq
fn max_value[T:Gt[T]](lhs: T, rhs: T) -> T {
    if lhs > rhs {
        ret lhs
    }
    ret rhs
}
```

Dynamic trait objects use `dyn Trait`:

```enq
fn consume(value: dyn Score) -> usize {
    ret value.score()
}

let score = Fixed{11_usize} as dyn Score
```

Object-unsafe trait shapes are rejected.

## Context Managers

Types that implement `core::ops::ContextManager` can be used with `with`:

```enq
import core::ops::ContextManager

struct Resource {
    value: u32
}

impl ContextManager for Resource {
    fn with_enter(self: Resource) -> Resource {
        ret self
    }

    fn with_exit(self: Resource) -> bool {
        ret true
    }
}

fn main() -> u32 {
    with Resource{7_u32} as resource {
        let seen = resource.value
    }
    ret 0_u32
}
```

`TcpStream` and `TcpListener` implement this trait in the standard library.

## Unsafe And EHIR Blocks

Some `core` internals use `unsafe` and embedded `ehir` blocks to call native
runtime support. Application code should normally stay in safe Encore and rely
on `core`/`std` wrappers.
