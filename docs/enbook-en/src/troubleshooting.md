# Troubleshooting

Fix the earliest relevant diagnostic before changing unrelated code. A useful
report contains the compiler release, host/target, exact command, manifest,
small reproducer, and complete diagnostic including notes.

## Installation and dependencies

| Symptom | First checks | Avoid |
| --- | --- | --- |
| `encore` not found | absolute binary path, PATH, new terminal | reinstalling before checking PATH |
| compiler runs but link fails | selected target, driver, SDK/sysroot | mixing MSVC and GNU libraries |
| unresolved `std` import | declared dependency and `encore sync` | copying a developer's absolute path |
| no matching package version | requirements, lockfile, configured index | silently changing all versions |
| archive checksum mismatch | immutable URL and expected checksum | bypassing verification |
| named Neumann asset returns 404 | whether that release is published | assuming the book publishes binaries |

A dependency cache and a compiler installation are different directories.
Keep a failing lockfile as evidence before deliberately updating it.

## Language diagnostics

**Does not compile:** this complete program passes an out-of-range literal:

```encore
fn byte(value: u8) -> u8 { ret value }

fn main() -> u32 {
    let value = byte(256)
    ret 0_u32
}
```

Expect `integer-literal-out-of-range`. Use a fitting value or change the API
to a larger type; a cast is not validation of untrusted input.

Other common rules:

- `unknown-token` for `0b102`: binary literals allow only zero and one.
- `mutable-receiver-required`: check both the binding and the receiver's
  `mut` contract. Do not add `unsafe` to silence a capability error.
- `frozen-region-mutation`: a shared snapshot cannot become mutable again.
- A consumed sending path or already joined handle: move the use before
  transfer, or use the returned result; do not reuse the consumed owner.
- Unknown type after an import failure: resolve the import first. Downstream
  unknown-type messages may all come from the same missing dependency.

Read [Concurrency](concurrency.md) for complete sending/frozen examples.

## Editor differs from terminal

Run `encore check` from the same project root. Compare the compiler/LSP
versions, environment, selected workspace, and dependency resolution. Check
whether Zed launched the intended global `encore-lsp` binary. Restart that
language server after an update; restarting a terminal does not replace an
already running process.

`//! Module description` belongs at module scope; `/// Declaration description`
belongs directly before its declaration. Missing hover prose is not necessarily
a missing symbol: check the source documentation too.

## Report a minimal example

Remove unrelated modules until the error still reproduces. Include whether
`check`, `build`, and execution agree. For suspected cache problems record
warm and clean project-local results separately. Never include credentials or
private source just because it happened to be in an environment dump.
