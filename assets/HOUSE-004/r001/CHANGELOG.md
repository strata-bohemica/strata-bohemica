# HOUSE-004 r001 — changelog

- Brief: `content/research/museum-lba/HOUSE-BRIEF.md` v1 (owner decisions 2026-11-20), SB-023 part 1 (assets only); contract `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` + `RETURN.md`.
- New asset: type A house, 15 × 5.5 m, three rooms (east 9 m with a pebble-paved hearth on the axis, middle 2.5 m, west 3.5 m outer), after Březno u Loun house 57 (dating doubtful). Three daub finishes as separate GLBs: `house_004_plain.glb`, `house_004_limewash.glb`, `house_004_pattern.glb`.
- Structure follows HOUSE-002 r001 (mesh nodes, anchors, +Z front, ridge along X) so the museum can swap it in.
- Deviations: JPEG textures embedded instead of PNG (size); a 4th untextured material `Stone` for the hearth paving inside the `Frame` mesh; no `.blend` (the generator is the source); west room 3.5 m outer / 3.23 m clear against house 57's 3 m west room (`D-houses-recon.md`; not a brief value); central ridge-post row (house 57 is not three-aisled) and door in the east room (the source hints at a middle-room entrance), both F; door 1.60 m and partition passages 1.70 m clear, so people stoop (phase-2 limitation).

## Review fixes (SB-023 phase 1, 2026-11-20)

- Godot 4.5.1 Compatibility village-angle views at 1280×800 (ortho 25 and 16, grid with PERSON-001 beside the door, clean) rendered windowed on the local display (Mesa OpenGL 4.6, Intel UHD 620): new `source/godot/run_village_views.sh` and `village_views.gd`, called from `build_all.sh`. Removed the false "no GPU" claim.
- PROVENANCE, CHECKS and `asset.json`: every brief quotation checked against HOUSE-BRIEF.md v1. Values not in the brief are now cited to `D-houses-recon.md` (house 57) or to the SB-023 phase-1 assignment.
- `asset.json`: added `reference_ids` and `fixture_hashes` (template fields; `fixture_hashes` replaces `input_hashes` and adds the research notes and the kit template). Renamed `not_a_brezince_plan` to `not_a_breznice_plan`. Added deviations.
- `checks/spatial_check.json`: fixture paths are repo-relative.
- Previews: the A/B lineups and finishes sheets are kept only here (HOUSE-005 references them). Godot A/B side-by-side added.
- GLBs unchanged (same SHA-256 as before this round).
