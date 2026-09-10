# Coverage and Current Limitations

This book describes the Neumann source line, not the old 0.2 release.
A source feature, a passing local test, and a published cross-platform release
are different milestones. Check the installed compiler's `--version` before
comparing diagnostics. Do not treat unreleased package URLs as available.

## Find a feature

| Language area | Explanation | Source-backed example/check |
| --- | --- | --- |
| literals, radix, inference, casts | [literals](features/literals.md), [operators](features/operators-and-casts.md) | guide numeric/Unicode test; compiler numeric-literal regressions |
| bindings, static, inline/node types, mutation | [values](values-and-sharing.md), [bindings](features/bindings-and-static.md), [methods](features/methods.md) | guide bindings/methods; compiler mutable-receiver tests |
| functions, generics, closures, traits and dyn | [functions](features/functions-and-generics.md), [closures](features/closures.md), [traits](features/traits-and-dyn.md) | guide feature examples; compiler generic/trait/closure regressions |
| enums, matching, conditions, iteration | [enums](features/enums-and-match.md), [loops](features/loops-and-ranges.md) | guide feature examples; compiler exhaustive-match tests |
| arrays, tuples, vectors, strings | [collections](features/collections.md), [strings](features/strings-and-fstrings.md) | guide collections and text-report cases |
| modules, imports, docs, packages, cfg | [imports](features/imports-and-visibility.md), [packages](packages.md), [attributes](features/attributes-and-cfg.md) | compiled guide module graph |
| Result, propagation, resources | [errors](designing-programs.md), [context managers](features/context-managers.md) | guide Result example and argument tests |
| async/await, spawn/join, sending/frozen | [concurrency](concurrency.md), [parallel project](parallel-project.md) | guide parallel/async examples; compiler transfer-negative tests |
| macros and decorators | [macros](features/macros.md), [decorators](features/decorators.md) | guide feature examples; compiler expansion/decorator regressions |
| extern, unsafe, EHIR, ABI | [unsafe](features/unsafe-and-ehir.md), [memory model](memory-model.md) | guide native fragment; compiler native/stack-escape regressions |

This is a navigation/coverage map, not a claim that every boundary condition
has been verified on every target. Library pages explain representative APIs,
not a complete generated API reference.

## Boundaries to know

- Neumann's release and index publication must complete before fresh-cache
  installation and `index@...@0.0.0` examples can be verified end to end.
- Native/cross compilation needs the matching compiler driver, linker, target
  libraries and SDK. See [targets](targets.md); macOS SDKs are not redistributed.
- The text-report project's file-reading API lacks a structured read error.
  Its existence check is not a race-free or permission-complete I/O guarantee.
- Out-of-range literals are checked; that does not establish a universal
  checked runtime-arithmetic contract. Keep calculations in range.
- Node ownership, mutable capabilities, and thread transfer are distinct.
  Passing a node to `spawn` without an appropriate contract is not a supported
  workaround for shared mutation.
- A successful `check` cannot prove native linkability or runtime correctness.
  LSP diagnostics also do not replace executing tests.

See [troubleshooting](troubleshooting.md) for reducing a failure and reporting
the command, target, version, and smallest reproducer.

## Build the book locally

From the compiler repository root:

```sh
mdbook build docs/enbook-en
cd docs/enbook-en/examples/guide
encore check
encore test --jobs 2
encore build
```

The guide's relative dependency points to the sibling development index.
This is a contributor fixture, not the manifest to copy into an application.
The tutorials instead instruct readers to create their own project and add
published dependencies. Before publication, local fixture results do not
substitute for the clean-install reader walkthrough.
