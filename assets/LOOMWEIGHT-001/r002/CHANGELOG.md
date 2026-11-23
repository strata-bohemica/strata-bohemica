# LOOMWEIGHT-001 r002 — changelog

## r002 (2026-11-23) — BREZ-007 detail revision of the single weights

- **Card:** `team/museum-kanban/tasks/BREZ-007.md` (modelling part). Source sheet: `team/evidence/breznice/BREZ-006/README.md`. Owner decisions 2026-11-23: specimen A 26 664 accepted; raise the hole; add wear of the lower hole edge; neutral name „závaží“.
- **Contract:** opus-v2 `COMMON.md` and `RETURN.md`, kit spec 2.0. r001 is unchanged.

### Delivered

- `models/loomweight.glb` (256 tris, budget 300) and `models/loomweight_marked.glb` (306, budget 330).
- Same body, atlas (pixel-identical to r001), material, dimple and anchors names as r001. `cord_hole` moves to y = 0.1124 m.
- Labelled stills for BREZ-007: `previews/BREZ-007_1_celek.png` and `previews/BREZ-007_2_otvor_sikme_svetlo.png` (same piece, real Godot GPU captures with a caption band added below the render).
- r001 → r002 comparisons with the same scene and light: `previews/compare_r001_r002_godot_{whole,hole_raking,hole_raking_back}.png`, `previews/compare_front_hole_r001_r002.png`.
- Generator, `.blend`, independent checks; new `source/hole_wear_check.py` (wear and hole height measured on the export, r001 as control).

### Changes

1. Hole centre raised from 0.355 to 0.275 of the height below the top (O: A 26 664 drawing via BREZ-006).
2. Wear: the lower third of the opening is widened and rounded at both mouths (extent M on the specimen; size R: ≤ 3 mm wide, 6 mm deep).
3. Hole has 12 facets (r001: 8).

### Deviations

1. **Fragment and deposit are not regenerated.** The card names only the two single models. They stay r001 assets with the r001 hole at y = 0.10 m. If the deposit should also get the r002 hole, that is a separate decision (deposit budget 2,600 would be exceeded with the r002 meshes as they are: 7 × 256 + 3 × 306 alone is 2,710).
2. **Toolchain:** bpy 5.0.1 (PyPI, via uv) on Linux instead of Blender 5.2.3 on macOS. Blender is not installed on this machine; the precedent is HOUSE-004 r002. The atlas PNG bytes differ from r001, the decoded pixels are identical.
3. **Not redone:** village views at ortho 25/16, PERSON/POT/HOUSE scale stills, the 24-row GPU render-info probe, height bracket. Body and size are unchanged; the change is a hole detail. The headless 24-row count is still reported.
4. **GPU capture size** is the window size the compositor gave (1882 × 1000, logged), not 1280 × 800.
5. **No ZIP** is produced. r002 is made inside the studio repository, as HOUSE-004 r002 (no ZIP), not returned from outside.
6. Repo intake tool `tools/inspect_asset.py` not run (does not know batch-3 IDs), as r001.
