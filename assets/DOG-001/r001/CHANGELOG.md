# DOG-001 r001 — changelog

## r001 (2026-11-07) — first dog

**Brief:** `art/briefs/economy-batch8/DOG-001.md` (economy batch 8 overnight backlog, a proposal, not a frozen pack) with `art/briefs/economy-batch8/README.md` and the shared rules of `art/briefs/economy-batch4/README.md`, executed under `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` and `RETURN.md` with kit metadata spec 2.0.

### Added

- `models/dog.glb`: a medium-sized generic dog (R). Withers ≈ 0.52 m, ear tips 0.71 m, nose to tail tip 1.11 m; 960 triangles, 1 material, one 256² atlas with four coat columns (tawny, grey agouti, dark with tan underside, pale cream) selected with `uv1_offset`.
- Rig following ANIMAL-001: `root, pelvis, spine1, spine2, neck, head, tail1, tail2, leg_{FL,FR,HL,HR}_{1,2,3}` plus paw bones `leg_*_4` — 24 bones, ≤ 2 weights per vertex.
- Ten in-place clips at 60 fps: the eight required `idle` (2 s loop), `walk` (0.5 s loop, 1.2 m/s), `trot` (0.4 s loop, 2.5 m/s), `sit` (1.0 s), `lie_down` (1.8 s), `lie_idle` (2 s loop), `stand_up` (1.4 s), `sniff_ground` (2 s loop), plus `sit_idle` (2 s loop) and `sit_up` (0.8 s).
- Anchors as exported nodes: `base_center` (root) and `head_lead` (on bone `neck`, collar point).
- Reproducible generator, native `.blend`, independent GLB parser with its own skinning, Blender re-import, Godot A/B import probe, GPU capture scripts and the preview composer (`source/`).
- Previews: six standard stills plus dog close-ups; village views at size 25 and 16 (grid and clean); close, scale, coat and pose line-ups; contact and culling evidence; loop and transition sheets; MP4/GIF of all clips, walk/trot ground speed, a herding walk at size 16 and 25 and a gather demo at size 16.

### Deviations from the brief

- **Extra clips** `sit_idle` and `sit_up`, so `sit` can be held and left without a pop.
- **Paw bones** (`leg_*_4`) beyond the ANIMAL-001 naming, so a planted paw stays flat; the tail therefore has 2 bones, and there are no jaw or ear bones (24-bone limit).
- **60 fps keys** (ANIMAL-001: 30) so the 2.5 m/s trot stays within 1 mm of the floor between keys; Godot must import with `animation/fps=60`.
- **Demo villager:** MILK-001 `person_herding` is not merged, so the accepted PERSON-001 r002 (`idle`, `walk`) is used.
- **Intake:** the repository intake tool does not support this ID; independent measurements are in `checks/` and the tool was not edited.

### Iterations made during this revision (all before return)

- Ring frames for body/head/neck no longer flip when a section turns past 45° (the first build twisted the neck and muzzle shells).
- Per-vertex coat shading replaced the height-based gradient so the back stays dark when the dog sits or lies.
- Neck lengthened and lowered, head enlarged, skull/muzzle made blockier; torso and legs thickened 8 % and coats darkened after the first Godot village captures (the dog read as a thin, pale fox at size 16).
- Sniff posture: head fixed at ~67° nose-down with the neck solved for ≥ 12 mm muzzle clearance over the whole loop (the first version hung the head almost vertically from an over-bent neck).
- Sit and lying tails solved to rest on the floor; the first sit tail went through the floor and lifted the whole body.
- Gait loops reduced to one stride cycle (walk 0.5 s, trot 0.4 s) and Godot import fps set to 60 after the A/B probe showed a 13.5 mm deviation with Godot's default 30 fps import.
