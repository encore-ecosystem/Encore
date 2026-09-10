# Installation and Editor Setup

Our goal is to run `encore --version`, create a project, and see a useful
diagnostic in an editor. No compiler checkout should be required to use a
published distribution.

## Choose a matching compiler and book

Use an official immutable release from the
[Encore releases page](https://github.com/encore-ecosystem/encore/releases).
This checkout documents `0.0.0-neumann`. Until that release and its package
index are published, the instructions below are release instructions, not a
working download of an already available Neumann binary. An older compiler is
not a substitute for validating these examples. Compiler contributors can use
the source-build instructions in the repository README meanwhile.

## Linux and macOS

Install `curl`, `tar`, `clang`, and either `sha256sum` or `shasum`. The `extreme`
build profile also needs an appropriate LLVM linker. Use your distribution's
package manager; on macOS, install the command-line developer tools if missing.

Download the installer so you can inspect it before running it:

```sh
curl --proto '=https' --tlsv1.2 -fsSL \
  https://raw.githubusercontent.com/encore-ecosystem/encore/trunk/install.sh \
  -o install-encore.sh
sh install-encore.sh --version 0.0.0-neumann
export PATH="$HOME/.encore/bin:$PATH"
encore --version
clang --version
```

The expected Encore version is `encore 0.0.0-neumann`. Add the PATH export to
your shell startup file to keep it across sessions. The installer chooses the
host architecture and checks the downloaded archive's SHA-256 before replacing
an installation. It does not install the system C toolchain.

Use `--install-dir /absolute/path` for another location. Updating and removing
the managed installation are explicit operations:

```sh
encore self update --check
encore self update
# Only when you intend to remove the managed installation:
sh install-encore.sh --uninstall
```

## Windows

The shell installer is for Linux/macOS. On Windows, download the release ZIP
matching the architecture **and ABI** you intend to use, plus its `.sha256`
asset. For example, the x86-64 MSVC archive is named
`encore-x86_64-pc-windows-msvc.zip`.

In PowerShell, inspect its hash and compare it with the checksum asset:

```powershell
Get-FileHash .\encore-x86_64-pc-windows-msvc.zip -Algorithm SHA256
Get-Content .\encore-x86_64-pc-windows-msvc.zip.sha256
```

Stop on a mismatch. Extract the complete distribution into a new directory;
keep `bin`, `lib`, `share`, and `VERSION` together. Add its `bin` directory to
your user PATH and open a new terminal. Install the matching native toolchain:
MSVC targets need the Windows SDK and MSVC build tools in addition to the
configured compiler driver; GNU targets need the corresponding GNU-compatible
toolchain. Do not mix their libraries. See [targets](targets.md).

Run `encore --version`, `encore target`, and then the hello program in
[Getting Started](getting-started.md). Verifying a version is not enough to
prove that the linker and runtime libraries are available.

## Zed and the language server

Install/enable the Encore language extension in Zed. The extension supplies
language identification and its language-server integration; the compiler
distribution supplies the matching `encore-lsp` executable. Make its `bin`
directory visible to the environment that launches Zed, not only to one shell.
Restart the language server after replacing its binary.

Open a **project folder containing `encore.toml`**, resolve its dependencies
with `encore sync`, and open `src/main.enq`. Check three independent features:

1. Hover over a documented imported symbol such as `println`.
2. Request completion after `import std::`.
3. Introduce an unknown name, observe the diagnostic, then undo the edit.

If the terminal checker works but the editor does not, verify which server
binary the extension launched and inspect the language-server log. Do not
start another server in a terminal expecting it to attach to Zed: LSP uses the
editor's stdio connection. See [troubleshooting](troubleshooting.md).

Zed's [language configuration documentation](https://zed.dev/docs/configuring-languages)
explains per-language formatting and explicit language-server binary overrides.
Use the server identifier registered by your Encore extension rather than
copying another language's settings unchanged.

## Check your setup

**Exercise:** open a fresh terminal and run `encore --version` again.

<details><summary>Solution when only the original terminal works</summary>

The temporary PATH export was not saved, or the application was launched with
an older environment. Persist the correct `bin` path and relaunch the editor.
Reinstalling the compiler is unnecessary if its absolute path already works.

</details>
