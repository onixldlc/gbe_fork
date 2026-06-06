#!/usr/bin/env bash
#
# Wrapper to mimic the env CS:GO (or any Source/Source2 title) uses when
# loading a plugin, then probe a .so with the dltest binary.
#
# Usage:
#   run_dltest.sh <game-root> <relative-or-absolute-path-to.so> [symbol ...]
#
# Example:
#   run_dltest.sh "/var/opt/steamlibrary/steamapps/common/csgo legacy" \
#                 csgo/addons/cvar-unhide.so
#
# Tip: prepend LD_DEBUG=libs to this script invocation to see the loader trace.

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <game-root> <so-path> [symbol ...]" 1>&2
  exit 3
fi

game_root="$1"; shift
so_path="$1"; shift

# locate the freshly-built dltest binary
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
dltest_bin=""
for cand in \
  "$script_dir/dltest" \
  "$script_dir/dltest_x64" \
  "$script_dir/dltest_x86" \
  "$repo_root"/build/linux/gmake/release/tools/dltest/dltest_x64 \
  "$repo_root"/build/linux/gmake/release/tools/dltest/dltest_x86 \
  "$repo_root"/build/linux/gmake/debug/tools/dltest/dltest_x64 \
  "$repo_root"/build/linux/gmake/debug/tools/dltest/dltest_x86; do
  if [[ -x "$cand" ]]; then dltest_bin="$cand"; break; fi
done
if [[ -z "$dltest_bin" ]]; then
  echo "dltest binary not found — build first:" 1>&2
  echo "  quick:  tools/dltest/build_standalone.sh" 1>&2
  echo "  full:   ./build_linux_premake.sh" 1>&2
  exit 1
fi

cd "$game_root"

# Mimic the loader paths Source uses. Adjust if your title differs.
extra_paths="$PWD/bin/linux64:$PWD/bin"
[[ -d "$PWD/csgo/bin/linux64" ]] && extra_paths="$PWD/csgo/bin/linux64:$extra_paths"

export LD_LIBRARY_PATH="${extra_paths}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
echo "cwd:             $PWD"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "dltest:          $dltest_bin"
echo

exec "$dltest_bin" "$so_path" "$@"
