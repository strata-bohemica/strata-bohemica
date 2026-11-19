#!/usr/bin/env bash
# Runs the museum_village checks headless with isolated Godot user dirs.
# usage: checks/museum_village/run.sh [test_name ...]   (default: all)
# The engine comes from $GODOT, else .runs/tools/Godot_v4.5.1-stable_linux.x86_64, else `godot` on PATH.
set -euo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
godot="${GODOT:-}"
if [[ -z "$godot" ]]; then
  if [[ -x "$here/.runs/tools/Godot_v4.5.1-stable_linux.x86_64" ]]; then godot="$here/.runs/tools/Godot_v4.5.1-stable_linux.x86_64"; else godot="$(command -v godot)"; fi
fi
state="$(mktemp -d)"
trap 'rm -rf "$state"' EXIT
mkdir -p "$state/data" "$state/config" "$state/cache"
export XDG_DATA_HOME="$state/data" XDG_CONFIG_HOME="$state/config" XDG_CACHE_HOME="$state/cache"
cd "$here"
"$godot" --headless --path . --import --quit >/dev/null 2>&1
tests=("$@")
if (( ${#tests[@]} == 0 )); then tests=(core data boundary view); fi
status=0
for name in "${tests[@]}"; do
  set +e
  out="$(timeout 120 "$godot" --headless --path . --script "res://checks/museum_village/test_$name.gd" 2>&1)"
  code=$?
  set -e
  printf '%s\n' "$out" | grep -vE '^(Godot Engine|[[:space:]]*$)' || true
  if [[ $code -ne 0 ]]; then printf 'exit %s from test_%s\n' "$code" "$name" >&2; status=1; fi
done
exit $status
