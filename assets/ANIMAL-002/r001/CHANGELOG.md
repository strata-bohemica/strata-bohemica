# ANIMAL-002 r001 — changelog

## r001 (first return)

**Brief:** `art/briefs/economy-batch5/ANIMAL-002.md`, pig with piglet, from economy batch 5, which is a proposal and not a frozen pack. The shared rules come from `economy-batch5/README.md` and `economy-batch4/README.md`. The contract is opus-v2 `COMMON.md` / `RETURN.md` with kit spec 2.0.

### Added
- `models/pig.glb`: adult pig with 1088 triangles, 1 material and a 512² atlas, rigged with 20 joints. Six in-place clips:
  - `idle` 2 s, loop
  - `walk` 1 s, loop, 1.0 m/s
  - `root_forage` 3 s, loop
  - `lie_down` 2 s, once
  - `lie_idle` 2 s, loop
  - `stand_up` 2 s, once
- `models/piglet.glb`: piglet with 592 triangles and the same material, atlas and rig scheme. Three clips:
  - `idle` 2 s
  - `walk` 1 s, 0.5 m/s
  - `trot` 1 s, 1.0 m/s, used to follow the sow
- Anchors `base_center` and `head_lead` on both models, using the ANIMAL-001 convention.
- A shared kit atlas with 4 coat columns per species, selected with `uv1_offset`. Piglet column 1 is striped.
- A reproducible generator, native `.blend` sources, independent checks (GLB parser with skinning, Blender re-import, Godot import A/B, reopen/re-export, determinism) and GPU previews and videos.

### Changes relative to the ANIMAL-001 r001 pipeline it was adapted from
- New species tables for the pig and piglet. The mesh adds a bristle crest, erect forward-tipped ears and a flat snout-disc cap.
- The gait code is generalised (`GAITS`, `gait_spec`) to cover walk and diagonal trot. The stance cannon tilt is set to 0, so planted hooves stay level. The measured contact speed equals the authored speed (−1.000 m/s pig walk).
- New `root_forage` clip and design solve. The forequarters lower and the snout reaches 4 mm above the floor in 3 pushes per loop.
- The floor-correction envelope tapers to zero at the ends of one-shot clips. As a result, `lie_down` and `stand_up` start and end exactly on the `idle` and `lie_idle` keys (≤ 1e-7).
- The playback hoof-lift margin is reduced from 0.3 mm to 0.1 mm, so lifted swing hooves rest on the floor instead of hovering.
- The inspector adds a 2 mm-contact hoof-speed metric, per-model hoof thresholds and a transition-continuity check.
- Godot demo: VEG-001 oak_autumn, ANIMAL-001 sheep, PERSON **r002**, a placeholder pen, acorn and rooted-soil props, and sow + piglets follow and village-loop videos.

### Deviations
- FENCE-001 is not merged, so a preview-only placeholder pen at the FENCE-001 brief size is used.
- The rig is kept exactly as in ANIMAL-001, with no jaw or ear bones. Rooting uses head, neck and forequarters only.
- The piglet has only the three clips the brief lists, with no lie or forage clip.
- The repository intake tool does not know this ID. It was not run and not edited. Independent checks are in `checks/` instead.
