# LOOM-001 r001 — changelog

**Brief:** LOOM-001 r001 upright loom study. This is a draft in `content/research/next-batch/material-culture.md` §5, dispatched by `art/briefs/economy-batch5/README.md` (proposal, not a frozen pack). Contract: opus-v2 COMMON/RETURN, kit spec 2.0.

## r001 (first return)

- New kit:
  - `models/loom_frame.glb` (760 triangles)
  - `models/loom_weaving.glb` (row `weights_base_down`, 5,226 triangles of which 3,168 are weights)
  - `models/loom_weaving_base_up.glb` (row `weights_base_up`, same counts)
- Weights are 18 instances of the unchanged LOOMWEIGHT-001 r001 mesh in two staggered ranks. The warp is alpha-mask cards (`LOOM_warp`, the only doubleSided material).
- Anchors: `base_center`, `weaver_origin`, `cloth_face`, `weights_row_center`, plus `wall_contact`.
- Work history: a previous agent session built the generator and first exports and was then terminated by a runtime restart. This session verified those exports by independent parse and rebuild (byte-identical), then completed the job:
  - added tie-loop meshes through each weight hole for close-up contact;
  - fixed the Blender preview placement of PERSON, which now uses the imported `weaver_origin` and the rig root;
  - switched the Blender stills to EEVEE so alpha cards and per-material culling render honestly;
  - wrote all check tooling, the Godot import/GPU captures, metadata and documentation.

## Deviations

- **Three GLBs instead of two.** The second row option is a sibling file (`loom_weaving_base_up.glb`), because glTF core has no visibility switch and one file with both rows would overlap 36 weights. Both row nodes keep the brief's names. The manager may merge the files and toggle the nodes at runtime.
- **Added `tie_loops`.** These are 1,080 triangles; the non-weight total of 2,058 stays within the 2,500 budget.
- **Added the supplementary anchor `wall_contact`.**
- **Weight count follows the brief (18),** not the economy note's 24.
- **`tools/inspect_asset.py` was not used**, because it does not know this ID. Independent checks are in `checks/`.
