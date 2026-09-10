# Getting Started

First complete [Installation and Editor Setup](installation.md). This chapter
is a command reference for your first project; next build the
[text-report tutorial](text-report.md).

Create a package in an empty directory:

```sh
mkdir hello
cd hello
encore init --name hello
```

`init` initializes the current directory; `--name` sets the package name,
not the name of a subdirectory to create.

`encore init` creates:

```text
encore.toml
src/main.enq
README.md
.gitignore
```

A minimal executable is:

```enq
import std::io::println

fn main() -> u32 {
    println("hello")
    ret 0_u32
}
```

If the package uses `std`, add it from the official package index:

```sh
encore add std
```

The command resolves the package, writes `encore.lock`, and updates the
manifest:

```toml
[project]
name = "hello"
target = "auto"
version = "0.0.0"
description = ""
readme = "README.md"
licence = "MIT"
dependencies = [
    "index@std",
]
```

Do not copy an absolute path from the compiler source checkout into an
application manifest. `path@...` is intended for local package development;
published packages use `index@...` references.

## Commands

Run these from the package directory:

```sh
encore sync
encore build
encore run
encore test
encore check
encore lint
encore format --check
encore add <package>
encore update
encore self update
```

The dependency commands have distinct behavior:

- `encore add <name>` adds the latest non-yanked index version and locks its
  complete dependency graph;
- `encore sync` restores exactly what is recorded in `encore.lock` and does
  not select newer index versions;
- `encore update` refreshes index metadata and rewrites the lockfile with the
  latest available versions.

Compiler updates are intentionally separate from dependency updates:

```sh
encore self channel
encore self channel beta
encore self update --check
encore self update
encore self install 0.0.0-neumann
```

`stable` is the default compiler channel. `beta` receives numbered preview
releases and `nightly` receives date-stamped builds. The selected channel is
stored in the managed Encore installation. An explicit `self install` does not
change it.

Commit both `encore.toml` and `encore.lock` for applications. Once package
archives are cached, ordinary builds do not need the index. See
[Packages And Build Scripts](packages.md) for cache, offline, and source-reference
details.

Common flags:

```sh
encore run -- arg1 arg2
encore test --filter dict
encore lint --deny missing-public-docstring
encore format
encore build --profile release
encore build --target aarch64-unknown-linux-gnu
```

The default `dev` profile uses `-O0` without debug information. `debug` adds
debug information and frame pointers. `release`
uses portable `-O2`. `extreme` enables `-O3`, ThinLTO through LLVM `lld`, and
32-byte hot-loop alignment; for a host build it also targets the native CPU
unless `target-cpu` is configured.

`encore run` is only available for executable packages. Program arguments after
`--` are passed to the compiled binary.

## Tests

Unit tests are ordinary functions marked with `#attr(test)`. `encore test`
discovers them across loaded refrains, compiles each test with a small harness,
and treats the test as passed when it returns `true`.

```enq
#attr(test)
fn math_works() -> bool {
    ret 2_u32 + 2_u32 == 4_u32
}
```

Test functions should:

- return `bool`;
- take no parameters;
- be non-generic;
- use `true` for pass and `false` for fail.

The test harness wraps the function in a generated executable `main`, so the
rest of the program can stay unchanged.

CI and large projects can list the test set and let the bounded worker pool run
it in parallel:

```sh
encore test --list --format json
encore test --jobs 8 --report target/test-results.json
```

Test results are reported in stable discovery order even though execution is
parallel.

Standalone negative tests can declare an expected compiler diagnostic in their
first kilobyte with `// @expect.compile_error=message`. The test passes only
when compilation fails and its captured output contains `message`; an unrelated
compiler or backend failure is reported as a failed test.

## Examples

Practical programs live in `examples/` and resolve libraries through the
official package index:

```sh
cd examples/echo
encore run -- hello beta

cd ../wc
encore run -- src/main.enq

```

The examples cover CLI programs, sorting, dictionaries, paths, strings,
filesystem operations, Unicode output, networking and terminal rendering.
