# Encore Examples

Each directory is an independent Encore project. Build or run it with the
native compiler:

```sh
cd echo
encore build --profile release
encore run
```

Examples that accept arguments use the `--` separator:

```sh
cd echo
encore run -- hello Encore
```

This directory keeps practical programs and focused demonstrations of Encore's
distinctive features. Basic syntax is covered by the
[language book](../docs/enbook-en/src/SUMMARY.md); compiler regressions belong
in `tests/`.

- Command-line tools: `echo`, `cat`, `wc`, `lslite`, `toml_reader`.
- Algorithms: `aho_corasick`, `binsearch`, `merge_sort`, `quick_sort`, `gradient`.
- Terminal output and networking: `hello`, `donut`, `hello_server`.
- Language and runtime: `add_two_structs`, `any_pointer`, `heap`, `try_result`,
  `ehir_blocks`, `refrains`.

Nested library packages, such as `refrains/math`, use `encore check`; build
their parent application to exercise linking.

Concurrency examples:

- `async_pipeline` demonstrates lazy futures, wakeups, polling and `await`;
- `multithreading` divides CPU work between native threads with `spawn` and
  collects typed results with `JoinHandle::join`.

`decorator_profile` demonstrates a parameterized compile-time decorator with
the exact `@RENDER_PROFILE.profile("draw_frame")` manager syntax.

`bare_metal` is a freestanding Cortex-M project. It demonstrates a custom
startup source, memory layout, target flags, and linked firmware ELF without
requiring board-specific behavior in the compiler.
