# HOUSE-005 r001 — changelog

- Brief: `content/research/museum-lba/HOUSE-BRIEF.md` v1 (owner decisions 2026-11-20), SB-023 part 1 (assets only); contract `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` + `RETURN.md`.
- New asset: type B house, 8.5 × 5 m, three rows of posts, undivided interior, central hearth (F), after the Liptice farmstead dwelling. Three daub finishes as separate GLBs: `house_005_plain.glb`, `house_005_limewash.glb`, `house_005_pattern.glb`.
- Structure follows HOUSE-002 r001 (mesh nodes, anchors, +Z front, ridge along X) so the museum can swap it in.
- Deviations: JPEG textures embedded instead of PNG (size); no `.blend` (the generator is the source); central hearth and the 0.8–0.9 m door range are F design choices from the SB-023 phase-1 assignment (2026-11-20), not brief values; door 1.60 m clear, so people stoop (phase-2 limitation).

## Review fixes (SB-023 phase 1, 2026-11-20)

- Godot 4.5.1 Compatibility village-angle views at 1280×800 (ortho 25 and 16, grid with PERSON-001 beside the door, clean) rendered windowed on the local display (Mesa OpenGL 4.6, Intel UHD 620): new `source/godot/run_village_views.sh` and `village_views.gd`, called from `build_all.sh`. Removed the false "no GPU" claim.
- PROVENANCE, CHECKS and `asset.json`: every brief quotation checked against HOUSE-BRIEF.md v1. Values not in the brief are now cited to `D-houses-recon.md` (house 57) or to the SB-023 phase-1 assignment.
- `asset.json`: added `reference_ids` and `fixture_hashes` (template fields; `fixture_hashes` replaces `input_hashes` and adds the research notes and the kit template). Renamed `not_a_brezince_plan` to `not_a_breznice_plan`. Added deviations.
- `checks/spatial_check.json`: fixture paths are repo-relative.
- `interior_center` anchor moved from (−3, 0, 0) near the west gable to the interior centre (0, 0, 0). It now coincides with `hearth_spot`. Only this node translation changed, but it changes all three GLBs (new SHA-256 in `asset.json`).
- Previews: duplicate A/B lineups and finishes sheets removed; see `../../HOUSE-004/r001/previews/`.
