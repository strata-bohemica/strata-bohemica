#!/usr/bin/env bash
# Renders the PNG and ICO exports from the SVGs written by build_brand.py.
# Usage: export.sh BRAND_DIR   (the directory build_brand.py wrote into)
# Needs: rsvg-convert (librsvg) and ImageMagick (magick).
set -euo pipefail
d="${1:?usage: export.sh BRAND_DIR}"
cd "$d"

r() { rsvg-convert -w "$2" "$1" -o "$3"; }

r social/social-preview.svg 1280 social/social-preview.png
r readme/banner-dark.svg 2560 readme/banner-dark@2x.png
r readme/banner-light.svg 2560 readme/banner-light@2x.png
r icons/avatar.svg 512 icons/avatar-512.png
r icons/avatar.svg 1024 icons/avatar-1024.png
r icons/apple-touch-icon.svg 180 icons/apple-touch-icon.png
r icons/favicon.svg 48 icons/favicon-48.png
r icons/favicon-32.svg 32 icons/favicon-32.png
r icons/favicon-16.svg 16 icons/favicon-16.png
magick icons/favicon-16.png icons/favicon-32.png icons/favicon-48.png icons/favicon.ico

for s in logo/logo-horizontal-dark logo/logo-horizontal-light logo/logo-stacked-dark logo/logo-stacked-light; do
  rsvg-convert -z 2 "$s.svg" -o "$s@2x.png"
done
for s in dark light; do r "logo/mark-$s.svg" 1024 "logo/mark-$s.png"; done
