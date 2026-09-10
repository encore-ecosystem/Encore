# Attributes, `cfg`, and Tests

Compile-time metadata begins with `#`. `#cfg(...)` selects an item for a
target; `#attr(test)` registers a test, and other `#attr(...)` values guide
compiler lowering. These are not runtime calls.

```encore
{{#include ../../examples/guide/src/features/mod.enq:attributes}}
```

Common `cfg` predicates include `windows`, `unix`, `target_os = "..."`, plus
`all(...)`, `any(...)`, and `not(...)`.

Use `cfg` for declarations that require a platform or feature, not a runtime
`if` around code that cannot compile on the target. Keep each supported target's
API shape consistent where callers expect a common interface.

`#attr(test)` functions take no parameters, are non-generic, and return `bool`.
True means pass. `#attr(decorator)` declares compile-time wrapping behavior;
see [decorators](decorators.md). An arbitrary attribute name is not a portable
extension point just because it parses. Only rely on implemented, documented
attributes for the compiler version in use.

See [packages](../packages.md#conditional-compilation) for CLI configuration
and build metadata. Test each configuration you distribute: compiling one
branch does not type-check code excluded by another target's configuration.
