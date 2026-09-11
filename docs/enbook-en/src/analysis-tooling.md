# Analysis and tooling architecture

Encore source tooling is built around one demand-driven semantic database.
The compiler, `encore check`, `encore lint`, the formatter, LSP, and IDE clients
must not implement separate name-resolution or type systems.

The semantic pipeline is:

1. lossless per-file syntax and parsed AST;
2. a project module graph and per-module definition map;
3. semantic HIR with stable module, definition, body, expression, and type IDs;
4. name resolution, type inference, trait obligations, and control-flow facts;
5. structured diagnostics, lint findings, formatting, and IDE queries;
6. EHIR lowering and backend code generation.

The shared query layer performs fast, structured checks first. Checks which
still depend on the mature lowering validator (including some ownership,
generic-bound, async, and exhaustive-match rules) run through a
validation-only translation pass which discards EHIR output. This preserves
complete compiler behaviour while those checks migrate into reusable queries.

The separately distributed LSP remains a thin JSON-RPC transport adapter over
the compiler's public analysis database, formatter, lint engine, project
configuration, ranges, and suggestions; it does not contain a second language
analyzer.

Changing a function body must not invalidate unrelated module interfaces.
Changing a public signature invalidates only queries which read that
definition. Query outputs are immutable values and do not perform filesystem
I/O, which permits future parallel evaluation and persistent caching.

## Diagnostics

A diagnostic contains a stable code, severity, primary message, primary and
secondary labelled spans, notes, help, and zero or more source suggestions.
Suggestions carry an applicability classification so only
`machine-applicable` edits may be applied automatically.

Terminal, JSON, LSP, and IDE output are projections of this same structured
value. No consumer reconstructs labels or fixes by parsing human-readable
messages.

## Project configuration

Tooling configuration lives in `encore.toml`:

```toml
[lint]
default = "warn"
dependencies = "allow"
cap = "deny"

[lint.rules]
unused = "warn"
unused-imports = "deny"
unreachable-code = "deny"
missing-public-docstring = "deny"

[format]
line-width = 100
indent-width = 4
newline-style = "auto"
trailing-comma = "vertical"
reorder-imports = true
format-docstrings = true
```

Unknown keys, rule names, and values are errors. Command-line lint levels
override manifest defaults. LSP and direct IDE clients receive the normalized
configuration from the project layer rather than parsing TOML themselves.
`missing-public-docstring` is `allow` by default and must be enabled explicitly
for projects which require documentation on every public API item.
`dependencies = "allow"` skips dependency linting; any other level analyzes
loaded dependency modules at that uniform capped level. `newline-style =
"auto"` produces deterministic LF output; use `"crlf"` for an explicit CRLF
policy.
