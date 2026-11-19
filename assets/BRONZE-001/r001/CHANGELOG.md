# BRONZE-001 — changelog

## r001 (2026-11-07)

Brief: `art/briefs/economy-batch4/BRONZE-001.md` + `art/briefs/economy-batch4/README.md` (economy batch 4, proposal), base draft `content/research/next-batch/material-culture.md` §5 “BRONZE-001 r001”; contract `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` / `RETURN.md`, kit spec 2.0.

### Delivered

- `models/axe_winged_hafted.glb` (228 tris) — winged bronze head, lashing, knee-shaped haft (R); nodes `grip`, `grip_secondary`, `edge_contact`, `base_center`.
- `models/axe_head_scrap.glb` (128 tris) — broken winged head + blade fragment for the scrap/recycling state.
- `models/knife_bronze.glb` (214 tris) — curved blade, ring-ended tang, organic handle plates; `grip`, `edge_contact`, `base_center`.
- `models/chopping_block.glb` (168 tris) — stump with split pieces and chips; `base_center`, `chop_target`, `worker_origin`.
- `models/person_chopping.glb` — PERSON-001 r002 body/rig/skin/palette byte-identical; clips `chop_enter`, `chop` (1.5 s loop), `chop_exit`, `fell_enter`, `fell` (1.6 s loop), `fell_exit`; new node `axe_hold` under `hand.R`.
- Kit: 2 materials, 1 shared 512² procedural atlas; all single-sided, opaque, no extensions.
- Source generators, independent checks (GLB parse, Blender re-import, reopen, determinism, contact, Godot import A/B, GPU captures), standard stills, village ortho 25/16 views, contact/culling close-ups, loop/transition sheets, MP4/GIF.

### Resume note

The job was started by an earlier agent session that was terminated by a runtime restart after exporting first GLBs. This session verified those exports by rebuilding them from the returned source in a scratch copy (byte-identical) and by independent parsing, then completed the checks, previews and documents. One change was made to the motion after review (below); the prop GLBs are the original exports.

### Changes during r001 review

- `gen_chopping.py`: chop-impact trunk crouch reduced (`B_CHOP_IMP` pelvis z −0.105 → −0.075 m). The deeper crouch let the left thigh show through the skirt at keys 11–20. The blade contact is unchanged (−4 mm into the block top); `person_chopping.glb` was regenerated.

### Deviations from the brief / draft

- File names, ≤ 300-tri budget and `grip` node follow the batch-4 brief, not the earlier draft (`axe_hafted.glb`, ≤ 900 tris, `hand_grip`). The head is a separate material primitive inside the `AXE` mesh, not a separate `axe_head` mesh. The knife has one handle option.
- Added transition clips (`*_enter`, `*_exit`) so every sequence starts and ends on the r002 idle pose with the axe carried in the right hand.
- `fell` is 1.6 s. The brief gives ~1.5 s only for `chop`.
- No trunk anchor on the person (only hand attachments are allowed). The oak placement for `fell` is documented (`CHECKS.md`, `asset.json`, `checks/contact_check.json`).
- Extra anchors: `grip_secondary`, `edge_contact`, `base_center`, `chop_target`, `worker_origin`.
- Exaggeration factor 1.0 (none).
- `tools/inspect_asset.py` does not support batch-4 IDs. It was not run or edited; `source/inspect_glb.py` gives the independent measurements instead.
