# THRESH-001 r001 — changelog

Brief: `art/briefs/economy-batch4/THRESH-001.md` with the shared rules in `art/briefs/economy-batch4/README.md` (economy batch 4, proposal, not a frozen pack). Contract: `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` and `RETURN.md`, kit metadata spec 2.0.

## r001 (first return)

- New prop kit (one material, one 512² atlas): `threshing_floor_clean`, `threshing_floor_strewn` (same footprint, root and anchors), `sheaf_bundle`, `beating_stick`, `winnowing_tray`, `grain_heap_small`, `chaff_heap_small`, `chaff_heap_large`, `straw_bundle`.
- New character GLB `person_threshing.glb`: PERSON-001 r002 body/rig/skin/palette unchanged, r002 clips replaced by `thresh_enter`, `thresh` (loop), `thresh_exit` and `winnow` (loop); new nodes `stick_hold` and `tray_hold` under `hand.R`.
- Independent checks (GLB parse, Blender re-import, skinned contact/intersection, Godot import A/B + GPU captures), reopen/rebuild determinism, Blender and Godot previews, MP4/GIF.

### Work history inside r001

- The job was started by an earlier agent session that was terminated by a runtime restart after exporting the GLBs. This session verified those GLBs by parsing and re-import before reuse, then changed:
  - **thresh posture:** the left thigh poked through the tunic at the hip in the earlier pose. The pelvis share of the forward lean was cut (0.30 → 0.16, spine/chest take more) and the pelvis drop reduced (≤ 0.07 m instead of ≤ 0.115 m); the lean at the strike was raised (59° → 72° total) so both hands still reach the stick (the first change had left the left hand 3 cm short, now 0 IK error).
  - **winnow grip:** the palms floated ~10 mm off the tray end walls; `PALM_OUT` 0.018 → 0.0085 m (now ≤ 0.93 mm).
  - **winnow toss:** lift 0.075 → 0.115 m, pitch 9°/−6° → 13°/−8° for readability at village zoom.
  - **colours:** straw, ear, chaff and grain atlas base colours darkened (chaff was nearly white in the Godot GPU view).
  - **sheaf length:** ear tufts shortened; 0.725 m → 0.676 m to meet the ≤ 0.7 m limit.
- Added the full check/preview pipeline (`source/build_all.sh` and helpers adapted from the accepted WORK-001 r001 return).

### Deviations

- `winnow` has no enter/exit clip; its first key is not the r002 idle pose (≤ 82.5° arm difference). Cross-fade in the game. `thresh_enter`/`thresh_exit` start/end exactly on r002 idle.
- Extra anchors `strike_target`, `tray_rest`, `stick_rest` (floors) and `tip` (stick) beyond the required set.
- The stick is in the right hand from the first key of `thresh_enter`.
- On the strewn floor the stick tip presses 1.7 mm into the chaff-litter patch at the deepest strike (1.65 mm above the clean floor).
- The repo intake tool `tools/inspect_asset.py` was not run (it does not know batch-4 IDs); independent measurements are supplied instead.
