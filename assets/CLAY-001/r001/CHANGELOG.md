# CLAY-001 r001 — changelog

## r001 (this return)

The brief is `art/briefs/economy-batch4/CLAY-001.md` plus the shared `README.md` (proposal brief, not a frozen pack). The contract is `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` and `RETURN.md`, with kit spec 2.0.

### Delivered
- **Pits:** `clay_pit_fresh.glb` and `clay_pit_worked.glb`, two mutually exclusive states with the same origin and anchor names. `checks/ground_cut.json` gives the terrain-hole outline for each.
- **Heaps:** `clay_heap_small.glb`, `clay_heap_medium.glb` and `clay_heap_large.glb`.
- **Mix:** `daub_mix_patch.glb`.
- **Wall patches:** `wall_patch_fresh.glb` and `wall_patch_white.glb`, fitted to the HOUSE-001 front wall left of the door at `(-1.1465, 0.60, 1.50)` in HOUSE space.
- **Tool:** `digging_stick.glb`, with `grip` and `tip` anchors.
- **Character:** `person_clay.glb`. It is the PERSON r002 body/rig/skin, unchanged, with in-place loops `dig` (4.2 s), `tread_mix` (4.0 s) and `plaster` (4.0 s), plus the new `tool_hold` node under `hand.R`.
- **Shared material and texture:** 2 prop materials (`CLAY_kit`, `CLAY_wet`) and one 512² atlas.

### Work in this session (resumed job)
- Re-generated the previous session's GLBs from `source/`. They came out byte-identical, so the generator and the shipped files matched.
- **`plaster` fixes.** The independent export check found two defects:
  - A whole-body "pop": the pelvis dropped 0.16 m in about 3 frames between strokes. It was fixed in three steps:
    - The second stroke was reordered upward.
    - The press, smear, lift and travel phases were re-timed.
    - The crouch is now rate-limited (`plaster_kk`, a soft dilation over ±0.5 s).
  - The palm passing up to 95 mm through the wall plane during the idle-to-wall approach. The hands now travel to the first stroke along a straight path that stays in front of the wall. A short idle-to-IK blend happens near the body.
  - Result: the largest per-key rotation step fell from 30.9° to 21.4°, and the minimum palm-to-wall distance is now +11.9 mm (was −95 mm).
- **`dig`:** the withdraw phase was lengthened (lever end 0.62 → 0.58, withdraw end 0.82 → 0.84). The largest per-key step went from 24.7° to 22.9°.
- **Clay colours:** the yellow-grey clay colours were darkened about 10% (`clay`, `clay_grey`), so heaps and pit interiors no longer read as cream or white under Godot daylight.
- **Checks, previews and documents added:** the independent checks (GLB parse, Blender re-import and contact, Godot import, state check and probe), the Blender and Godot GPU previews, the GIF/MP4, `asset.json`, these documents, the rebuild scripts and the ZIP.

### Deviations and limits
- The glTF root node names differ per state (`CLAY_PIT_FRESH`/`CLAY_PIT_WORKED`, `WALL_PATCH_FRESH`/`WALL_PATCH_WHITE`, `CLAY_HEAP_*`). Origin, identity transform and anchor names are identical.
- Pits, the mix patch and the wall patches should use `cast_shadow = OFF` in Godot. With default casting, the single-sided pit bowl shows heavy self-shadow acne in the Compatibility renderer (`previews/godot_pits_ortho6_cast_shadow_on_acne.png`).
- The host terrain must be cut under each pit (`checks/ground_cut.json`).
- Counting `person_clay`'s unchanged r002 `body`/`garment`, the kit has 4 unique materials. The props alone use 2, within the brief's 3.
- The `plaster` generator diagnostic `max_ik_reach_error_m = 0.128` is not localised to specific frames. The exported skin contact is measured independently and is within limits (CHECKS).
- Fast transients remain in `dig`: up to 22.9° per 1/30 s on the forearm/hand during the thrust and withdraw. This is intended as a vigorous stroke and is visible in the GIF.
