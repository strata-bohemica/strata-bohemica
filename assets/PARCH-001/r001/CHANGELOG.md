# PARCH-001 r001 — changelog

## r001 (first revision)

Brief: `art/briefs/economy-batch9/PARCH-001.md` (economy batch 9, proposal, not a frozen pack) with the batch README and the shared rules in `art/briefs/economy-batch4/README.md`; contract `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` + `RETURN.md`, kit metadata spec 2.0.

Added:

- `models/parching_tray_sherd.glb` (192 tris): ~0.51 × 0.46 m re-used base sherd / clay plate with a low rim, one fresh break, scorched dish and sooted convex underside.
- `models/parching_tray_with_grain.glb` (272 tris): the same tray with a thin parched-grain layer.
- `models/stir_stick.glb` (104 tris): 0.66 m peeled stick with a charred end; anchors `grip`, `tip`.
- `models/person_parching.glb`: PERSON-001 r002 (byte-identical body/rig/skin/palette/materials/carry_anchor) with `parch_enter` (2.0 s), `parch_stir` (2.4 s loop), `parch_exit` (2.0 s), hand node `stick_hold` (hand.R) and placement nodes `hearth_place`, `tray_place`, `stick_rest`.
- Shared 128² procedural atlas, one kit material.
- Reproducible generators, native `.blend` sources, independent GLB/Blender/Godot checks, Godot GPU previews, GIF/MP4.

Deviations from the brief (also in `asset.json` `deviations`):

- The host is KILN-001 `hearth_open_top` on `hearth_base` with `fire_embers` (not `fire_lit`: flames would pass through the tray).
- The tray sits inside the stone ring on the ember logs: the ring's inner radius (0.31 m) is wider than a ~0.5 m tray, so it cannot bridge the stones.
- `parch_stir` starts/ends on a crouch base pose; `parch_enter`/`parch_exit` connect it to r002 idle t=0. Only the three new clips are exported (as WORK-001 / COOK-002 did).
- The stick is picked up from the floor at the worker's right (`stick_rest`) during `parch_enter` and laid back there in `parch_exit`.

Iterations made during this revision (quality loop): the pick-up reach was brought within arm length (trunk roll/lean towards the stick, stick rest moved closer); the carry path was raised and moved outward after the contact check showed the stick passing through the chest, thigh, stones and tray rim; finger curl at the floor pick-up reduced so the fingers stay above the floor; tray underside winding fixed (32 inconsistent edges → 0); grain UVs no longer wrap per vertex and the grain got a 64 px atlas block; tray and soot colours adjusted for contrast with the KILN-001 base.
