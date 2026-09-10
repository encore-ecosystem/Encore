#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: build-target-kit.sh --host TRIPLE --target TRIPLE --toolchain DIR --platform DIR --out DIR --compiler PATH --linker PATH --archiver PATH [--sysroot PATH] [--compile-arg ARG] [--link-arg ARG] [--base-url URL]" >&2
  exit 2
}

host=
target=
toolchain=
platform=
out=
compiler=
linker=
archiver=
sysroot=
base_url=
compile_args=()
link_args=()
while (($#)); do
  case "$1" in
    --host) host=$2; shift 2 ;;
    --target) target=$2; shift 2 ;;
    --toolchain) toolchain=$2; shift 2 ;;
    --platform) platform=$2; shift 2 ;;
    --out) out=$2; shift 2 ;;
    --compiler) compiler=$2; shift 2 ;;
    --linker) linker=$2; shift 2 ;;
    --archiver) archiver=$2; shift 2 ;;
    --sysroot) sysroot=$2; shift 2 ;;
    --compile-arg) compile_args+=("$2"); shift 2 ;;
    --link-arg) link_args+=("$2"); shift 2 ;;
    --base-url) base_url=${2%/}; shift 2 ;;
    *) usage ;;
  esac
done

test -n "$host" && test -n "$target" && test -d "$toolchain" &&
  test -d "$platform" && test -n "$out" && test -n "$compiler" &&
  test -n "$linker" && test -n "$archiver" || usage

version=$(tr -d '\r\n' < "$(dirname "$0")/../VERSION")
version=${version%%-*}
abi=$(printf '%s\n' "$version" | awk -F. '{print $1 "." $2}')
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
payload="$work/payload"
mkdir -p "$payload/toolchain" "$out"
cp -RL "$toolchain"/. "$payload/toolchain/"
cp -RL "$platform" "$payload/platform"

compiler_path="toolchain/$compiler"
linker_path="toolchain/$linker"
archiver_path="toolchain/$archiver"
sysroot_path=
if test -n "$sysroot"; then sysroot_path="toolchain/$sysroot"; fi
for path in "$compiler_path" "$linker_path" "$archiver_path"; do
  test -f "$payload/$path" || { echo "missing target-kit tool: $path" >&2; exit 1; }
done
if test -n "$sysroot_path"; then test -d "$payload/$sysroot_path"; fi

compile_args_json=$(jq -n '$ARGS.positional' --args -- "${compile_args[@]}")
link_args_json=$(jq -n '$ARGS.positional' --args -- "${link_args[@]}")
jq -n \
  --arg abi "$abi" \
  --arg host "$host" \
  --arg target "$target" \
  --arg compiler "$compiler_path" \
  --arg linker "$linker_path" \
  --arg archiver "$archiver_path" \
  --arg sysroot "$sysroot_path" \
  --argjson compile_args "$compile_args_json" \
  --argjson link_args "$link_args_json" \
  '{
    schema: 1,
    abi: $abi,
    host: $host,
    target: $target,
    driver: "clang",
    compiler: $compiler,
    linker: $linker,
    archiver: $archiver,
    sysroot: $sysroot,
    cpu: "",
    features: "",
    compile_args: $compile_args,
    link_args: $link_args,
    runtime_sources: [],
    linker_script: "",
    hosted_runtime: true
  }' > "$payload/manifest.json"

find "$payload" -exec touch -t 200001010000.00 {} +
asset="target-kit-$host--$target.tar.xz"
tar -C "$payload" --sort=name --owner=0 --group=0 --numeric-owner -cJf "$out/$asset" .
checksum=$(sha256sum "$out/$asset" | awk '{print $1}')
printf '%s  %s\n' "$checksum" "$asset" > "$out/$asset.sha256"
archive="$asset"
if test -n "$base_url"; then archive="$base_url/$asset"; fi
jq -n \
  --arg abi "$abi" \
  --arg host "$host" \
  --arg target "$target" \
  --arg archive "$archive" \
  --arg sha256 "$checksum" \
  '{schema:1, abi:$abi, host:$host, target:$target, archive:$archive, sha256:$sha256, format:"tar.xz"}' \
  > "$out/target-kit-$host--$target.json"
