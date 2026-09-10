#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "usage: ci-produce-stage1.sh SEED_COMPILER PRODUCER SEED_TAG TARGET..." >&2
  exit 2
fi

seed_compiler=$1
producer=$2
seed_tag=$3
shift 3
targets=("$@")

case "$producer" in
  linux|darwin|darwin-intel) executable=encore ;;
  windows) executable=encore.exe ;;
  *) echo "unknown producer: $producer" >&2; exit 2 ;;
esac

release=$(tr -d '\r\n' < VERSION)
version=${release%%-*}
release_name=${release#*-}
test "$release" = "$version-$release_name"
target_kit_abi=$(printf '%s\n' "$version" | awk -F. '{print $1 "." $2}')
dependencies_checksum=$(awk 'NF {print tolower($1); exit}' \
  target/dependency-download/dependencies.tar.gz.sha256)
mkdir -p target/stage1-builder target/stage1-artifacts

"$seed_compiler" build --profile extreme
cp "target/extreme/$executable" "target/stage1-builder/$executable"
builder="$PWD/target/stage1-builder/$executable"
chmod +x "$builder" 2>/dev/null || true

# The transition seed and stage1 use the same immutable system-library input.
# Never replace the graph midway through self-hosting.
index_root="$PWD/../encore-index"
test -f "$index_root/packages/core/encore.toml"
export ENCORE_CORE_DIR="$index_root/packages/core"

for target in "${targets[@]}"; do
  target_executable=encore
  [[ "$target" == *-windows-* ]] && target_executable=encore.exe
  args=(build --profile extreme --target "$target")
  # Keep argv non-empty for the Bash 3 shipped by macOS under `set -u`.
  env_args=(env)

  case "$target" in
    aarch64-unknown-linux-gnu)
      : "${LLVM_MINGW_ROOT:?LLVM_MINGW_ROOT is required for Linux AArch64 stage1}"
      env_args+=("ENCORE_CC=$LLVM_MINGW_ROOT/bin/clang"
        "ENCORE_LINKER=$LLVM_MINGW_ROOT/bin/clang"
        "ENCORE_AR=$LLVM_MINGW_ROOT/bin/llvm-ar"
        "ENCORE_SYSROOT=$LLVM_MINGW_ROOT/linux-aarch64-sysroot")
      ;;
    x86_64-w64-windows-gnu|aarch64-w64-windows-gnu)
      : "${LLVM_MINGW_ROOT:?LLVM_MINGW_ROOT is required for Windows GNU stage1}"
      env_args+=("ENCORE_CC=$LLVM_MINGW_ROOT/bin/clang"
        "ENCORE_LINKER=$LLVM_MINGW_ROOT/bin/clang"
        "ENCORE_AR=$LLVM_MINGW_ROOT/bin/llvm-ar")
      ;;
  esac

  "${env_args[@]}" "$builder" "${args[@]}"
  source="target/$target/extreme/$target_executable"
  if [[ "$target" == "$(uname -m)-unknown-linux-gnu" && "$producer" == linux ]]; then
    source="target/$target/extreme/$target_executable"
  elif [[ "$target" == aarch64-apple-darwin && "$producer" == darwin ]]; then
    source="target/$target/extreme/$target_executable"
  elif [[ "$target" == x86_64-pc-windows-msvc && "$producer" == windows ]]; then
    source="target/$target/extreme/$target_executable"
  fi
  test -s "$source"

  destination="target/stage1-artifacts/$target"
  mkdir -p "$destination"
  cp "$source" "$destination/$target_executable"
  chmod +x "$destination/$target_executable" 2>/dev/null || true
  if command -v sha256sum >/dev/null 2>&1; then
    executable_checksum=$(sha256sum "$destination/$target_executable" | awk '{print $1}')
  else
    executable_checksum=$(shasum -a 256 "$destination/$target_executable" | awk '{print $1}')
  fi
  jq -n \
    --arg commit "$GITHUB_SHA" \
    --arg version "$version" \
    --arg nametag "$release_name" \
    --arg release "$release" \
    --arg seed "$seed_tag" \
    --arg producer "$producer" \
    --arg target "$target" \
    --arg target_kit_abi "$target_kit_abi" \
    --arg dependencies "$dependencies_checksum" \
    --arg executable "$target_executable" \
    --arg sha256 "$executable_checksum" \
    '{
      schema: 2,
      commit: $commit,
      version: $version,
      nametag: $nametag,
      release: $release,
      seed: $seed,
      producer: $producer,
      target: $target,
      target_kit_abi: $target_kit_abi,
      dependencies_sha256: $dependencies,
      executable: $executable,
      executable_sha256: $sha256
    }' > "$destination/manifest.json"
done
