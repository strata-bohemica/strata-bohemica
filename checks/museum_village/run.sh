#!/usr/bin/env bash
# Runs the museum_village checks headless with isolated Godot user dirs.
# usage: checks/museum_village/run.sh [test_name ...]   (default: all)
# `sync_assets` is the Python test of tools/sync_assets.py anchor normalisation (checks/sync_assets), not a Godot test.
# The engine comes from $GODOT, else .runs/tools/Godot_v4.5.1-stable_linux.x86_64, else `godot` on PATH.
set -euo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ "$*" == "sync_assets" ]]; then exec python3 -m unittest discover -s "$here/checks/sync_assets"; fi   # needs no engine
godot="${GODOT:-}"
if [[ -z "$godot" ]]; then
  if [[ -x "$here/.runs/tools/Godot_v4.5.1-stable_linux.x86_64" ]]; then godot="$here/.runs/tools/Godot_v4.5.1-stable_linux.x86_64"; else godot="$(command -v godot)"; fi
fi
state="$(mktemp -d)"
trap 'rm -rf "$state"' EXIT
mkdir -p "$state/data" "$state/config" "$state/cache"
export XDG_DATA_HOME="$state/data" XDG_CONFIG_HOME="$state/config" XDG_CACHE_HOME="$state/cache"
cd "$here"
"$godot" --headless --path . --import --quit >/dev/null 2>&1      # first pass extracts the model textures
"$godot" --headless --path . --import --quit >/dev/null 2>&1      # second pass: scenes pick them up
tests=("$@")
if (( ${#tests[@]} == 0 )); then tests=(sync_assets core epoch transition data terrain boundary view plough_team ui guards sound ambient camera object_view weather lighting); fi
status=0
for name in "${tests[@]}"; do
  if [[ "$name" == "sync_assets" ]]; then
    set +e
    out="$(python3 -m unittest discover -s "$here/checks/sync_assets" 2>&1)"
    code=$?
    set -e
    printf 'sync_assets: %s\n' "$(printf '%s\n' "$out" | tail -1)"
    if [[ $code -ne 0 ]]; then printf '%s\n' "$out" >&2; printf 'exit %s from sync_assets\n' "$code" >&2; status=1; fi
    continue
  fi
  set +e
  out="$(timeout 120 "$godot" --headless --path . --script "res://checks/museum_village/test_$name.gd" 2>&1)"
  code=$?
  set -e
  printf '%s\n' "$out" | grep -vE '^(Godot Engine|[[:space:]]*$)' || true
  if [[ $code -ne 0 ]]; then printf 'exit %s from test_%s\n' "$code" "$name" >&2; status=1; fi
done
exit $status
