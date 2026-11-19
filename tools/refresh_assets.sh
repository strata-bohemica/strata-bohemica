#!/usr/bin/env bash
# Bring assets/ up to date from the factory, with the import options the museum needs.
# usage: tools/refresh_assets.sh FACTORY_RETURNS_DIR     (needs the pinned Godot as $GODOT or on PATH)
set -euo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
godot="${GODOT:-$(command -v godot)}"
cd "$here"
python3 tools/sync_assets.py "$1"
"$godot" --headless --path . --import --quit >/dev/null 2>&1      # first import creates the .import files
python3 tools/import_settings.py
find assets -name '*.png' -delete -o -name '*.png.import' -delete    # extracted by that first import; not wanted
rm -rf .godot/imported                                              # drop scenes cached with the old options
"$godot" --headless --path . --import --quit >/dev/null 2>&1
echo "assets refreshed"
