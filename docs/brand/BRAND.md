# Strata Bohemica: brand

Digital open-air museum of Bohemian prehistory.

## Mark

Three contour lines around a patina-green pit: an excavation plan. Strata means layers, both the layers of soil and the layers of epochs the project uncovers. The pit is the sunken storage pit (zásobnice) the village scenes are built around. The green centre is bronze patina.

Use the mark on its own only where the name is already visible (avatar, favicon).

## Files

| File | Use |
|---|---|
| `logo/mark-dark.svg` / `mark-light.svg` / `mark-mono.svg` | Mark on dark, on light, one colour (`color` attribute sets it) |
| `logo/logo-horizontal-*.svg` | Mark + wordmark in a row (docs, slides, headers) |
| `logo/logo-stacked-*.svg` | Mark above wordmark with descriptor |
| `readme/banner-dark.svg` / `banner-light.svg` | Top of the repository README (1280 × 320) |
| `readme/banner-*@2x.png` | PNG fallback, 2560 × 640 |
| `readme/divider.svg` | Four-colour strata rule between README sections |
| `social/social-preview.png` | GitHub social preview, 1280 × 640 |
| `icons/avatar-512.png`, `avatar-1024.png` | GitHub profile or organisation avatar |
| `icons/favicon.ico`, `favicon.svg`, `favicon-32.svg`, `favicon-16.svg` | Web favicon; 32 px and 16 px are simplified |
| `icons/apple-touch-icon.png` | 180 × 180 |
| `tools/build_brand.py` | Regenerates every SVG (needs `uharfbuzz`, `fonttools`, the three fonts) |
| `tools/export.sh` | Renders the PNGs and `favicon.ico` from the SVGs (needs `rsvg-convert`, ImageMagick) |

SVG text is converted to outlines, so no font is needed to display the files.

## Colour

| Name | Hex | Use |
|---|---|---|
| Půda (soil) | `#1E1914` | Dark background |
| Inkoust (ink) | `#2A211A` | Text and wordmark on light |
| Humus | `#6B5238` | Layers, secondary text on light |
| Humus, light | `#8A6B4B` | Outer line on dark |
| Humus, dark | `#5A4635` | Outer line on light |
| Hlína (clay) | `#C46A3F` | Second line, large areas |
| Bronz (bronze) | `#D1A24B` | Third line on dark, accent text on dark |
| Bronz, dark | `#B8862F` | Third line on light |
| Měděnka (patina) | `#5E9C8A` | Centre, links, badges |
| Sláma (straw) | `#E6D5A8` | Taglines on dark, highlights |
| Kost (bone) | `#F3EBDD` | Light background, text on dark |

Clay and bronze on a light background are for graphics and large type only; use soil or humus for body text.

## Type

- **Fraunces** SemiBold: wordmark and headings
- **IBM Plex Sans**: text
- **IBM Plex Mono**: labels, inventory tags, screenshot captions

All three are SIL Open Font License.

## Rules

- Clear space around the mark: the width of its innermost ring.
- Minimum size: 16 px mark only, 120 px with wordmark.
- Do not recolour the lines, add gradients or shadows, or stretch the mark.
- Below 32 px use `favicon-32.svg` or `favicon-16.svg`; do not scale the full mark down.
