# ANIMAL-001 r001 — changelog

## r001 (2026-11-06) — first livestock kit

**Brief:** the draft "ANIMAL-001 r001 — cattle and sheep (first livestock kit)" in `content/research/next-batch/settlement-features.md` §6. It is a proposal, not a frozen pack. The job also uses the per-candidate notes (§3) and `content/research/next-batch/README.md`, executed under `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` and `RETURN.md` with kit metadata spec 2.0.

### Added

- `models/cattle.glb`: a small generic short-horned cow (R). Withers 1.15 m, nose to rump 1.83 m, 1554 triangles, 1 material, one 512² atlas.
- `models/sheep.glb`: a small, polled, short-tailed sheep in fleece (R). Withers ≈0.63 m, length 1.02 m, 962 triangles, same material and atlas.
- A shared quadruped rig (20 joints, 19 deforming, ≤ 2 weights per vertex): `root, pelvis, spine1, spine2, neck, head, tail1, tail2, leg_{FL,FR,HL,HR}_{1,2,3}`.
- Six in-place clips per species at 30 fps:
  - `idle` 2 s loop;
  - `walk` 1 s loop, authored for 0.8 m/s (sheep: two stride cycles per loop);
  - `graze` 2 s loop, head down;
  - `lie_down` 2 s, front knees first;
  - `lie_idle` 2 s loop;
  - `stand_up` 2 s, hindquarters first.
- Anchors as exported nodes: `base_center` (root) and `head_lead` (on bone `head`, at the throat).
- A shared procedural kit atlas with four restrained coat columns per species, selected in-engine with `uv1_offset`.
- A reproducible generator, native `.blend` sources, an independent GLB parser with its own skinning, a Blender re-import check, the Godot A/B import probe and GPU capture scripts, and the preview composer (`source/`).
- Previews: six standard stills, village views at size 25 and 16 (grid and clean), close and line-up views, coat variants, contact and culling evidence, loop and transition sheets, and MP4/GIF for the clips, the walking ground speed and the herd.

### Deviations from the draft brief

- **No FENCE-001 pen in the herd demo.** FENCE-001 was not returned in this batch.
- **No jaw bone** (marked optional, "jaw?"). Grazing and rumination use head and neck motion.
- **Sheep walk:** the 1 s loop contains two stride cycles so that sheep-sized strides (0.4 m) give the authored 0.8 m/s.
- **Herd demo materials:** each demo instance duplicates the imported material to set its coat offset. A game can share 4 + 4 material instances.
- **Intake:** the repository intake tool does not support this ID. Independent measurements are in `checks/` and the tool was not edited.
- **Preview lighting:** the preview sun uses a larger shadow bias (renderer setting). See `CHECKS.md`.

### Iterations made during this revision (all before return)

- Cattle proportions: deeper and lower belly (0.48 m), shorter and blockier head, thicker neck with a dewlap, smoother withers-to-poll topline, and length compressed to ~1.8 m (`FWD_SCALE` 0.93).
- Hind legs re-lofted along a straighter stifle–hock path. The earlier 75° bend folded the rings into spikes. Thigh rings were pulled inside the flank.
- Graze: the head now pitches nose-up relative to the neck, and a 2-D search picks the deepest reach; the muzzle ends 10–12 mm above the floor. The earlier version tucked the head under the chest.
- Walk: the cannon tilts by 35 % of the leg swing and the body drops 25 mm. This gives full IK reach without rolling the hoof, so planted hooves move at −0.785 m/s against 0.8 m/s authored. An airborne-only lower-leg raise keeps reach during swing.
- Kneel: the airborne raise is restricted to the walk, so the front carpi really rest on the floor in lie_down and stand_up.
- Contact: the generator also evaluates interpolated playback (slerp between keys) and lifts airborne hooves or the pelvis until no sample goes below −0.3 mm.
- Lying legs are tucked closer to the body. Coat noise was softened to remove streaks.
