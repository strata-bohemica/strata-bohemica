# WEAVE-001 — changelog

## r001 (first return)

Brief: `art/briefs/economy-batch8/WEAVE-001.md` r001 (economy batch 8 proposal). Contract: opus-v2 `COMMON.md` + `RETURN.md`, kit spec 2.0; character-motion rules from `art/briefs/economy-batch4/README.md`.

### Delivered

- `models/person_weaving.glb`: PERSON-001 r002 mesh, skin, bind pose, materials, palette and `carry_anchor` unchanged byte for byte. It adds five in-place clips and three hold nodes:
  - `weave_enter` (1.2 s)
  - `weave_pass` (3.0 s loop)
  - `weave_beat` (2.0 s loop)
  - `weave_shed_change` (2.0 s)
  - `weave_exit` (1.2 s)
  - holds: `bobbin_hold_L` on `hand.L`; `bobbin_hold_R` and `beater_hold` on `hand.R`
- `models/weft_bobbin.glb` (278 tris) and `models/sword_beater.glb` (272 tris), each with a `grip` node and one shared 128² atlas material.
- Placement uses only LOOM-001 r001's exported `weaver_origin`. Hands are measured against its `cloth_face` plane. During pass and beat they stay within 25.5–27.2 mm (Godot-evaluated) and 25.9–27.5 mm (numpy LBS), against the 30 mm limit.
- Godot 4.5.1 Compatibility/OpenGL import checks for configurations A and B. GPU stills and a 217-frame GPU sequence (enter → pass → beat ×2 → shed change → pass → exit) with the actual loom, delivered as MP4 and GIF.

### Deviations from the brief

1. **Two extra clips**, `weave_enter` and `weave_exit`, take the character from r002 idle t=0 to the shared READY pose and back. `weave_pass`, `weave_beat` and `weave_shed_change` all start and end on READY, so they can be chained in any order (WORK-001 precedent).
2. **`weave_shed_change` is a one-shot** clip that starts and ends on READY. The brief gives only "2 s". LOOM-001's heddle rod is static frame geometry, so the clip shows a grasp and a 10 mm forward / 12 mm up tug. It cannot show a real lift or a changed shed.
3. **Bobbin hand-over.** A left→right pass is done with two hands, so the bobbin uses two hold nodes with documented switch times (u = 0.50 and 0.90, where both holds coincide). The brief named only the beater's `grip`; the bobbin also has a `grip`.
4. The five PERSON r002 clips (idle, walk, …) are not repeated in `person_weaving.glb`. The batch-8 siblings and WORK-001 handle this the same way.
5. `tools/inspect_asset.py` was not run or edited. Independent measurements are in `checks/`.

### Known limits

- LOOM-001 places `weaver_origin` 0.70 m from the loom, so the READY lean is ~27°. A LOOM r002 `weaver_origin` around 0.45–0.5 m would allow a more upright stance; the clips would then need regenerating.
- Hands and props pass through LOOM's alpha-mask warp cards. Thread deformation is not modelled.
- The beater grip and knob (12–16 mm radius) sit in the fist inside the warp width and cross the warp-card planes by up to 8.4 mm. The blade itself stays between the layers (0.0 mm intrusion).
- Technique, tools and posture are R (see PROVENANCE.md). There is no historical approval.
