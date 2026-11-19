# WORK-001 r001 — changelog

Brief: WORK-001 r001, saddle-quern work study (`jobs/WORK-001.md`, `prompts/WORK-001.md`, handoff pack `bronze-bohemia-opus-v2`, kit metadata spec 2.0). This is the first revision.

## Added

- **`models/quern.glb`.** Lower saddle quern (504 triangles, 0.547 × 0.323 × 0.121 m). It has a restrained lengthwise concave working arc, base centre at the origin and its long axis along +Z. Anchors: `base_center`, `grind_target` (0, 0.11, 0) and `worker_origin` (0, 0, −0.55), plus two added anchors, `handstone_rest` and `grain_patch_spot`.
- **`models/handstone.glb`.** Handstone (192 triangles, 0.22 × 0.10 × 0.07 m). The origin is at the base centre and `handstone_grip` is at the geometric centre (0, 0.035, 0). The base follows the quern arc.
- **`models/grain_patch.glb`.** Sparse generic meal heaps (78 triangles, within 0.256 × 0.148 m).
- **Shared props atlas.** One material and one 256² atlas for all props, single-sided and opaque, with no extensions.
- **`models/person_grinding.glb`.** The unchanged PERSON-001 r001 body, rig and skin with three new clips:
  - `grind_enter` (1.2 s): neutral idle stance → both feet step back in a half crouch → both knees down → lean and grip;
  - `grind` (2.0 s seamless loop): two push/pull strokes moving the handstone ±0.11 m over the lower stone;
  - `grind_exit` (1.2 s): the reverse of `grind_enter`.
  - It also gains the `handstone_hold` node on `hand.R`.
- **`checks/attachment.json`.** The placement recipe, measured residuals and the Godot import settings.
- **Generators and verification.** Reproducible generators, the independent GLB parser, Blender re-import and contact tests, Godot import and GPU capture scripts and a one-command build (`source/`).
- **Previews.** Blender standard stills, Godot GPU village-angle, close, contact, culling and context stills, the 16-sample loop sheets, the transition sheet and the enter → 3 loops → exit MP4 and GIF.

## Changed relative to the PERSON-001 r001 fixture (in this copy only)

- `body` and `garment` are exported single-sided: `doubleSided` is omitted, which means false, instead of the fixture's `true`. This fixes the known culling defect for this study only. It does not imply that r001 was accepted.
- The five r001 clips and the preview-only pot proxy were removed from the copy. Mesh, UVs, weights, bones, bind pose, `carry_anchor` and the palette were not changed; they are byte-identical in the GLB.

## Deviations

- The quern height is 0.121 m against the brief's ~0.11 m. `grind_target` stays at 0.11 on the working-surface centre and the saddle ends rise 12 mm.
- Two extra quern anchors were added. The handstone rests at the back of the stroke (`handstone_rest`) so that enter and exit hand over to the loop at zero velocity.
- `grind_exit` is `grind_enter` in reverse time.
- Godot import needs `grind` loop_mode = LINEAR and the AnimationPlayer optimizer disabled. Godot's default optimizer shifts the handstone path by up to 3.4 mm.
- The transition sequence was revised after intake review: both feet step back in a half crouch and both knees go down together. This removed the one-knee lunge in which the raised left thigh showed through the tunic; skin weights untouched.
- The six standard stills now use the intake names `previews/front.png`, `side.png`, `back.png`, `top.png`, `isometric.png` and `wireframe.png`.
- Scratch and Godot projects were created next to the repository clone, not in `/tmp`, because `/tmp` is blocked in this environment.
