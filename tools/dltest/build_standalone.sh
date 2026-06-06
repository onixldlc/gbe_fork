#!/usr/bin/env bash
#
# Standalone build for dltest — no premake, no third-party deps. Just cc + libdl.
# Use this when you want the diagnostic in seconds without running the full
# emu build. Output: tools/dltest/dltest (next to the source).
#
# Build natively:
#   tools/dltest/build_standalone.sh
#
# Build inside the gbe-env:linux container (matches the runner toolchain):
#   podman run --rm -v "$PWD":/src -w /src ghcr.io/onixldlc/gbe-env:linux-latest \
#     bash tools/dltest/build_standalone.sh
#
# Cross-build 32-bit (needs gcc-multilib):
#   M32=1 tools/dltest/build_standalone.sh

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$script_dir/dltest.c"
out="$script_dir/dltest"

cc_bin="${CC:-}"
if [[ -z "$cc_bin" ]]; then
  for cand in cc gcc clang; do
    if command -v "$cand" >/dev/null 2>&1; then cc_bin="$cand"; break; fi
  done
fi
if [[ -z "$cc_bin" ]]; then
  echo "no C compiler found — install build-essential or set CC=..." 1>&2
  exit 1
fi

flags=( -O2 -Wall -Wextra )
[[ "${M32:-0}" = "1" ]] && { flags+=( -m32 ); out="${out}_x86"; }

echo "+ $cc_bin ${flags[*]} -o $out $src -ldl"
"$cc_bin" "${flags[@]}" -o "$out" "$src" -ldl

echo "built: $out"
"$out" 2>&1 | head -1 || true   # prints usage line to prove the binary runs
