# Introduction

Encore is a self-hosted programming language and native compiler built around
EHIR, the Encore High Intermediate Representation, and LLVM.

This book documents project setup, language syntax, packages, target
toolchains, the memory model, and the standard library.

## Who this book is for

You should have written a program in another language. You do not need to know
Rust, C++, LLVM, or systems programming. We introduce Encore's ownership and
concurrency rules before relying on them. The book is written for the Neumann
source line; a version named in an example is not evidence that its release
has already been published. See [current limitations](beta-notes.md).

## How to read it

Start with [installation](installation.md) and [Getting Started](getting-started.md).
Build the [text-report project](text-report.md), learn how [values and shared
nodes](values-and-sharing.md) behave, then try [parallel work](parallel-project.md).
The Language Reference is for looking up exact syntax after that first pass.
The formal ERN model and compiler internals are optional advanced reading.

Code labelled **complete program** can replace a project's `src/main.enq`.
A **fragment** needs the imports, types, and surrounding function described in
the text. **Does not compile** examples deliberately demonstrate a diagnostic;
do not paste them into a working program and expect success. Shell blocks omit
the prompt so you can copy them. Output is shown separately. Exercises include
solutions, but try the change before opening the answer.

This is a book, not a promise that every library function has a dedicated
chapter. The core/std pages explain common APIs and link them to examples;
declaration documentation and editor hover provide additional API detail.

## Repository Layout

| Path | Purpose |
| --- | --- |
| repository root | native compiler frontend and CLI |
| `src` | compiler, package manager, diagnostics and CLI |
| `tests` | compiler integration tests |
| `examples` | executable language examples |
| `docs/enbook-en` | this user guide |

Core, EHIR, backend, and standard-library packages are distributed through the
official `encore-ecosystem/encore-index` sparse registry.

## Requirements

- an installed Encore native compiler;
- `clang` or another configured target toolchain.
- `curl`, `tar`, and `sha256sum` or `shasum` when resolving index packages.

Verify the installation and target:

```sh
encore --version
encore target
```

Python is not part of the compiler or runtime. Historical bootstraps are not
part of the active Neumann release epoch.
