#!/usr/bin/env sh
set -eu

repository=${ENCORE_REPOSITORY:-encore-ecosystem/encore}
install_root=${ENCORE_HOME:-"$HOME/.encore"}
version=${ENCORE_VERSION:-latest}
release_base=${ENCORE_RELEASE_BASE_URL:-}
action=install

usage() {
    cat <<'EOF'
Usage: install.sh [options]

Options:
  --version <version>    Install a specific Encore release
  --install-dir <path>   Install into path instead of $HOME/.encore
  --update               Install the requested or latest release
  --uninstall            Remove the Encore installation
  -h, --help             Show this help
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --version)
            [ "$#" -ge 2 ] || { echo "--version requires a value" >&2; exit 2; }
            version=$2
            shift 2
            ;;
        --install-dir)
            [ "$#" -ge 2 ] || { echo "--install-dir requires a value" >&2; exit 2; }
            install_root=$2
            shift 2
            ;;
        --update) action=install; shift ;;
        --uninstall) action=uninstall; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

unsafe_install_root=false
case "/$install_root/" in
    */../*|*/./*) unsafe_install_root=true ;;
esac
case "$install_root" in
    ""|"$HOME"|"$HOME"/) unsafe_install_root=true ;;
esac
if [ -d "$install_root" ] && [ ! -L "$install_root" ]; then
    canonical_root=$(CDPATH= cd -- "$install_root" && pwd -P)
    canonical_home=$(CDPATH= cd -- "$HOME" && pwd -P)
    if [ "$canonical_root" = / ] || [ "$canonical_root" = "$canonical_home" ]; then unsafe_install_root=true; fi
else
    without_slashes=$(printf '%s' "$install_root" | tr -d '/')
    if [ -z "$without_slashes" ]; then unsafe_install_root=true; fi
fi
if [ "$unsafe_install_root" = true ]; then
    echo "Refusing unsafe Encore install directory: $install_root" >&2
    exit 1
fi

if [ "$action" = "uninstall" ]; then
    rm -rf "$install_root"
    echo "Removed Encore from $install_root"
    exit 0
fi

expected_release=$version
release_tag=$version
if [ "$version" != "latest" ]; then
    expected_release=${version#v}
    case "$version" in
        v*) ;;
        *) release_tag="v$version" ;;
    esac
fi

os=$(uname -s)
arch=$(uname -m)
case "$arch" in
    x86_64|amd64) arch=x86_64 ;;
    arm64|aarch64) arch=aarch64 ;;
    *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
esac
case "$os" in
    Linux) triple="${arch}-unknown-linux-gnu" ;;
    Darwin) triple="${arch}-apple-darwin" ;;
    *) echo "Unsupported operating system: $os" >&2; exit 1 ;;
esac

asset="encore-${triple}.tar.gz"
if [ -n "$release_base" ]; then
    case "$release_base" in
        https://*|file://*) ;;
        *) echo "ENCORE_RELEASE_BASE_URL must use https:// or file://" >&2; exit 1 ;;
    esac
    base_url=${release_base%/}
elif [ "$version" = "latest" ]; then
    base_url="https://github.com/${repository}/releases/latest/download"
else
    base_url="https://github.com/${repository}/releases/download/${release_tag}"
fi

download_dir=$(mktemp -d)
transaction_dir=
committed=false
cleanup() {
    if [ "$committed" != true ] && [ -n "$transaction_dir" ] && [ -d "$transaction_dir/previous" ] && [ ! -e "$install_root" ]; then
        mv "$transaction_dir/previous" "$install_root"
    fi
    rm -rf "$download_dir"
    if [ -n "$transaction_dir" ]; then rm -rf "$transaction_dir"; fi
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

for name in "$asset" "$asset.sha256"; do
    if [ -n "$release_base" ]; then
        curl --fail --location --silent --show-error "$base_url/$name" -o "$download_dir/$name"
    else
        curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 "$base_url/$name" -o "$download_dir/$name"
    fi
done

expected=$(awk 'NF { print $1; exit }' "$download_dir/$asset.sha256" | tr 'A-F' 'a-f')
case "$expected" in
    ""|*[!0-9a-f]*) echo "Invalid release checksum" >&2; exit 1 ;;
esac
[ "$(printf '%s' "$expected" | wc -c | tr -d ' ')" = 64 ] || { echo "Invalid release checksum" >&2; exit 1; }
if command -v sha256sum >/dev/null 2>&1; then
    actual=$(sha256sum "$download_dir/$asset" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    actual=$(shasum -a 256 "$download_dir/$asset" | awk '{print $1}')
else
    echo "Install sha256sum or shasum to verify the release" >&2
    exit 1
fi
if [ "$actual" != "$expected" ]; then
    echo "Checksum verification failed" >&2
    exit 1
fi

mkdir -p "$download_dir/unpack"
tar -tzf "$download_dir/$asset" > "$download_dir/archive.list"
while IFS= read -r path; do
    case "$path" in
        ""|/*|../*|*/../*|*/..) echo "Release archive contains an unsafe path: $path" >&2; exit 1 ;;
    esac
done < "$download_dir/archive.list"
tar -tvzf "$download_dir/$asset" > "$download_dir/archive.types"
while IFS= read -r entry; do
    case "$entry" in
        -*) ;;
        d*) ;;
        *) echo "Release archive contains links or special files" >&2; exit 1 ;;
    esac
done < "$download_dir/archive.types"
tar -xzf "$download_dir/$asset" -C "$download_dir/unpack"
package_count=$(find "$download_dir/unpack" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
[ "$package_count" = 1 ] || { echo "Release archive must contain exactly one package directory" >&2; exit 1; }
package_dir=$(find "$download_dir/unpack" -mindepth 1 -maxdepth 1 -type d | head -n 1)
[ -n "$package_dir" ] || { echo "Release archive is empty" >&2; exit 1; }
[ -s "$package_dir/bin/encore" ] || { echo "Release archive does not contain bin/encore" >&2; exit 1; }
[ -f "$package_dir/VERSION" ] || { echo "Release archive does not contain VERSION" >&2; exit 1; }
package_release=$(cat "$package_dir/VERSION")
# Legacy stable distributions remain installable during the named-release cutover.
if ! printf '%s\n' "$package_release" | LC_ALL=C grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[a-z][a-z0-9.-]*)?$'; then
    echo "Invalid release identity in VERSION" >&2
    exit 1
fi
if [ "$version" != "latest" ] && [ "$package_release" != "$expected_release" ]; then
    echo "Release version mismatch: requested $expected_release, archive contains $package_release" >&2
    exit 1
fi

install_parent=$(dirname -- "$install_root")
mkdir -p "$install_parent"
transaction_dir=$(mktemp -d "$install_parent/.encore-install.XXXXXX")
mkdir -p "$transaction_dir/new"
cp -R "$package_dir/bin" "$package_dir/lib" "$package_dir/share" "$package_dir/VERSION" "$transaction_dir/new/"
chmod +x "$transaction_dir/new/bin/encore"
installed_version=$("$transaction_dir/new/bin/encore" --version 2>/dev/null || true)
if [ "$installed_version" != "encore $package_release" ]; then
    echo "Compiler version mismatch: archive contains $package_release, binary reports '${installed_version:-unavailable}'" >&2
    exit 1
fi
if [ -e "$install_root" ] || [ -L "$install_root" ]; then
    mv "$install_root" "$transaction_dir/previous"
fi
mv "$transaction_dir/new" "$install_root"
committed=true

echo "Installed Encore $package_release in $install_root"
case ":${PATH}:" in
    *":$install_root/bin:"*) ;;
    *) echo "Add $install_root/bin to PATH" ;;
esac
