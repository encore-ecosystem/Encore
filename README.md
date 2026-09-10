# Encore

Encore is a self-hosted native programming language built on EHIR and LLVM

## Install

Linux and macOS require `curl`, `tar`, `clang`, and either `sha256sum` or
`shasum`:

```sh
curl --proto '=https' --tlsv1.2 -fsSL \
  https://raw.githubusercontent.com/encore-ecosystem/encore/trunk/install.sh | sh
export PATH="$HOME/.encore/bin:$PATH"
```

The installer downloads the release for the current architecture, verifies its
SHA-256 checksum and replaces an existing installation transactionally.

```sh
# Install an exact release.
curl --proto '=https' --tlsv1.2 -fsSL \
  https://raw.githubusercontent.com/encore-ecosystem/encore/trunk/install.sh |
  sh -s -- --version 0.0.0-neumann

~/.encore/bin/encore --version

# Remove Encore.
curl --proto '=https' --tlsv1.2 -fsSL \
  https://raw.githubusercontent.com/encore-ecosystem/encore/trunk/install.sh |
  sh -s -- --uninstall
```

Use `--install-dir <path>` for another location. The installer supports Linux
and macOS on x86-64 and AArch64.

## Quick Start

```sh
encore init --name hello
cd hello
encore run
encore test
encore build --profile release
```

Useful commands:

```sh
encore check
encore format
encore lint
encore add <package>
encore build --target <llvm-triple>
encore self update
```

Language, package and cross-compilation documentation is in
[`docs/enbook-en`](docs/enbook-en/).

## Development

An existing native compiler can build and test this repository:

```sh
./target/extreme/encore build --profile extreme
./target/extreme/encore test
```

The final two bootstrap compilers must be byte-identical.

## License

[MIT](LICENSE)
