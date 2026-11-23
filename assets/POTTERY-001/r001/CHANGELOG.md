# POTTERY-001 r001 — changelog

## r001 (2026-11-23) — SB-058 part 1: museum pottery package

- **Cards:** `team/museum-kanban/tasks/SB-058.md` (part 1: asset package), `SB-057.md` (scope). Basis: `team/evidence/breznice/BREZ-008/README.md`, BREZ-010 (firing deferred).
- **Owner decisions 2026-11-23** (in conversation, relayed by the dispatcher): CC BY 4.0 for the MUSEUM-018/019 models; choreography by splitting clips (enter / cycle / exit, no walking), no CraftProps code change; scope = existing MUSEUM-018 hand-forming as an experimental variant, no firing, no Hněvotín.
- **Contract:** opus-v2 `COMMON.md` + `RETURN.md`, kit spec 2.0; factory layout `museum-pottery-v3/POTTERY-001/r001` so the museum's `tools/sync_assets.py` can pick it up (models/*.glb + asset.json anchors + PROVENANCE.md + CHANGELOG.md).

### Delivered

- `models/person_forming.glb`: craft skin with `form_enter` (3.45 s), `form` (9.1 s, seamless cycle, raised bowl only), `form_exit` (3.45 s, smoothed bowl); static skin nodes `block_place` and `vessel_hold`.
- `models/work_block.glb`, `clay_stock.glb`, `clay_coil.glb`, `bowl_coil_raised.glb`, `bowl_smoothed.glb`: byte copies of MUSEUM-018.
- `source/craft_example.json`: proposed museum craft wiring (not applied).
- Independent checks (`checks/`), GPU and Blender stills, swap (form end → exit start) and loop-wrap pairs, motion GIF (`previews/`).

### Fixes after the independent review of PR #524 (head 3ba8781)

- Bowl choreography changed to the manager's decision (raised bowl only in `form`, one swap at `form_exit` 0 s); see changes 3 and 4 below.
- Preview pairs: both halves are centre-cropped to a common size (the old loop-wrap pair pasted a 1882 px still into a 930 px slot and lost its right half); the swap pair is now form 9.099 s → `form_exit` 0 s.
- Godot stills: AnimationPlayer in manual process mode, so the pose no longer advances in real time while a still is drawn.
- `craft_sim.gd`: blocks of 60, 37.3 and 18 s in 0.01 s steps; also counts skin nodes used by two props and lists each bowl change. `contact_check.py`: jump from each `form` key to `form_exit` 0 s.

### Changes against MUSEUM-019 `forming.glb`

1. The 16 s take `clay_forming` is cut at 3.45 s and 12.55 s. `form_enter` = take 0–3.45 s, `form` = 3.45–12.55 s, `form_exit` = 12.55–16 s. Pelvis path identical to the take in every key.
2. `station_stand` and `station_walk` are dropped (no walking; the museum's walker skin does the travel).
3. `FormingTransition` (blend-shape bowl inside the skin) is dropped. The two kit bowls are props: CraftProps shows `bowl_coil_raised` in `form_enter` and `form`, and swaps to `bowl_smoothed` once, at `form_exit` 0 s (manager decision after the PR #524 review; replaces the earlier swap at `form` 4.55 s with a reset to the raised bowl at every cycle start).
4. Hands stay on the raised-bowl wall geometry in every key of `form` and `form_exit` (the take's 7–9 s move to the smoothed wall is dropped, and no hand move between walls is added), so the cycle's last key equals its first. At `form_exit` 0 s, where the smoothed bowl appears, the hands are lifted above the rim; `form_exit` is as before this change (raised wall parameters while the hands lift out; 0 body vertices inside the smoothed bowl in all 139 keys).
5. Arm roll made continuous (upper arm and forearm twist about their own axis only). The take had a 113° single-key roll at 3.4 s (vertex step 10.7 cm per key); cutting the loop would have added two more. Now ≤ 3 cm per key everywhere.
6. Skin nodes `block_place` (work block root) and `vessel_hold` (bowl seat) added under `PERSON_rig`.

### Deviations

1. Discrete bowl swap instead of a continuous morph (CraftProps limit, owner decision (b)), once per block at `form_exit` 0 s. The smoothing itself is not shown inside the cycle; the visitor sees the raised bowl worked and the smoothed bowl when the worker settles out.
2. 3 fingertip vertices dip ≤ 3.59 mm into the raised bowl wall in 8 of 365 `form` keys (0.425–0.525 s, 8.625–8.675 s): hand entry / withdrawal, MUSEUM-019 hand targets. Not changed by the roll fix.
3. CraftTimeline starts `form_exit` wherever the cycle is at block end − 3.45 s: up to 13.4 cm body jump unless the block is 3.45 + n × 9.1 + 3.45 s (wiring note in CHECKS.md).
4. No village views at ortho 25/16 and no PERSON/POT/HOUSE line-up: the kit sizes are MUSEUM-018's, unchanged.
5. GPU captures at the window size the compositor gave, not forced to 1280 × 800.
6. No ZIP: made inside the studio repository (precedent HOUSE-004 r002, LOOMWEIGHT-001 r002).
7. Toolchain: bpy 5.0.1 from PyPI via uv (Blender not installed on this machine).
