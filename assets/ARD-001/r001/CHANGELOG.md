# ARD-001 r001 — changelog

Brief: `art/briefs/economy-batch6/ARD-001.md` (economy batch 6, a proposal and not a frozen pack), revision r001: wooden ard, yoke and ploughing. Shared rules are in `art/briefs/economy-batch4/README.md`. Contract: `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` and `RETURN.md` (kit spec 2.0).

## r001 (first return)

- **`models/ard.glb`.** A generic crook ard in working attitude, 2.06 m long:
  - One bent piece forms the share, sole and stilt.
  - A separate crook beam runs to the yoke, held by a wedge through the stilt/beam joint.
  - A T-handle tops the stilt; rawhide lashings bind the joint and the sole, and a peg sits across the beam end.
  - Anchors: `grip` on the T-handle centre and `yoke_hitch` at the beam end.
  - Origin is the share's soil-entry point, with the share tip 7 cm below y = 0.
  - 616 triangles, one shared material.
- **`models/yoke_pair.glb`.** A neck (withers) yoke for two ANIMAL-001 cattle 1.0 m apart:
  - A bowed beam with two neck seats, two pairs of pins and throat thongs.
  - A rope sling under the ard beam, behind the hitch peg.
  - Anchors: `cattle_l`, `cattle_r` and `beam_hitch`. Origin is the floor point midway between the cattle.
  - The seat height, pin spacing and thong path were measured on the actual cattle GLB (walk + idle keys).
  - Per-clip "bob" tables are included for an optional game-side adapter.
  - 986 triangles.
- **`models/furrow_strip.glb`.** A 1×4 m ploughed-strip decal with four 0.25 m furrows along +Z.
  - The top follows FIELD-001's soil level (y 0.012) with ridges up to 0.058 m and a skirt to y −0.03.
  - Anchor `base_center`. 640 triangles.
- **`models/person_ploughing.glb`.** The PERSON-001 r002 mesh, skin, bind pose, palette and materials, byte-identical, with three new in-place clips:
  - `plough_enter` (1.2 s) and `plough_exit` (1.2 s, the reverse) start and end on r002 `idle` t=0.
  - `plough_walk` is a 1.6 s loop at 0.6 m/s, with two 0.48 m steps, the trunk leaning forward and both hands on the T-handle.
  - New node `stilt_hold` under `hand.R`. `carry_anchor` is unchanged.
- **Shared atlas.** 256² `source/textures/ard_kit_atlas.png` (procedural): wood, dark wood, end grain, pins, rawhide, leather and a soil gradient.
- **Tooling.** Independent GLB parser, Blender re-import and contact checks, Godot import probe (configurations A and B), GPU stills, GIF/MP4, and a deterministic two-run rebuild with a reopen check.

## Iterations during r001 (from my own preview critique)

- Raised the T-handle grip from 0.42 to 0.50 m in front of the person and increased the trunk lean, so the arms reach instead of folding.
- Thickened the beam for readability at village scale.
- Hand contact: the palms first sat 14.6 mm inside the handle. I moved the wrist target out and increased finger curl, so palms now touch at −0.9 mm and fingers are within +0.2 mm.
- `plough_enter`: the hands swept through the handle end (−16 mm). I lifted the arms first and approached from above, closing the fingers last. The minimum is now −0.9 mm, only at the final key.
- Lowered the ridge height to reduce shoe sink on a strip.
- Yoke seat:
  - First sized for the walk only; the idle neck crest was 23 mm higher, so a static yoke would have entered the necks during idle.
  - The seat is now above both clips, with per-clip adapter tables.
  - The neck measurement now samples across the seat width, which catches neck roll.
  - The yoke ring count was set so vertices lie exactly on the seat underside.
- Rope sling: routed up behind the hitch peg so the peg clears the strands over the full bob range (≥ 10.7 mm).

## Deviations

- `person_ploughing.glb` carries only the three new clips. The r002 clips stay in PERSON-001 r002, as WORK-001's `person_grinding` did.
- Extra anchors not named in the brief: `beam_hitch` (yoke), `base_center` (strip), `stilt_hold` (person).
- Triangle budgets are my R choices; the brief gives none.
- Playback rules used by the demos are documented in `source/README.md`, not baked into the GLBs:
  - cattle walk at 0.75×,
  - team root moved at 0.6 m/s,
  - the optional yoke bob adapter.
- In the moving demo the team ploughs FIELD-001 bare tiles; furrow strips lie in the finished columns.
- Scratch, Godot projects and caches live outside the repository; `/tmp` was not used.
