# PERSON-001 r002 — changelog

Brief: `jobs/PERSON-001.md` / `prompts/PERSON-001.md`, handoff pack bronze-bohemia-opus-v2 (batch 2.0), metadata spec 1.0, revision r002 — "Correct character culling and minor sole clipping; preserve rig".

## Changes from r001

1. **Single-sided materials (culling fix).** `make_material()` now sets `use_backface_culling = True` on `body` and `garment`. The Blender glTF exporter writes `doubleSided = not use_backface_culling`, so r001 shipped `doubleSided: true` on both materials (contradicting its CHECKS). r002 exports no `doubleSided` key (= false) and no `alphaMode` key (= OPAQUE); Godot imports both surfaces as `CULL_BACK` (r001 fixture: `CULL_DISABLED`). Geometry was not changed: every part was already a closed outward-facing shell with a real skirt lining, and Godot GPU probes from below, inside the hem, at the feet, crown and sleeve show no holes, so no local face fix was needed.
2. **Swing/heel-off toe penetration fix.** r001 pivoted the heel-off rotation about the ball *sole* point while keeping the toe segment flat; that lowered the toe joint by 0.03·(1−cos θ) and pushed the flat toe up to 4.9 mm into the floor in late stance and the first swing frames. r002 pivots about the toe *joint* (`BALLJ0`), so the toe sole stays on y = 0, and adds `swing_clearance()`, a continuous lift of the swing ankle measured on the linear-blend-skinned shoe vertices (target 1.5 mm, ramped to 0 at lift-off and strike). Result: lowest vertex over each whole clip (8 samples per key) walk −0.38 mm, carry_walk −0.36 mm (r001 −4.91 mm); feet never float in stance.
3. **Only leg channels of walk and carry_walk changed:** thigh/shin/foot rotations by ≤ 1.70°; the other leg-chain channels (thigh/shin/foot/toe scale and translation, toe rotation) differ only by float32 export noise ≤ 1e-4. All 69 channels of idle, work and rest, the 47 remaining channels of walk/carry_walk (arms, trunk, head, pelvis translation), the 23-bone hierarchy and bind pose, skin, mesh buffers, palette and `carry_anchor` are bit-identical to r001 (`checks/r001_r002_parity.json`). Ground speeds and step lengths unchanged; stance contact slip measured on the GLB ≤ 0.11 mm per 1/30 s key.
4. **Preview proxy removed.** The non-exported `NOT_EXPORTED_pot_proxy` lathe was deleted from the generator/.blend; all contact previews and measurements use the actual POT-001 r001 GLB with the current adapter rule. `pot_profile()` is kept unchanged because it defines the carry-hand target (and therefore the anchor).
5. **Generator diagnostics.** The stance-slip check now includes toe sole points (because the pivot moved) and the report adds skinned-shoe minima. Palette output moved to `source/person_palette.png` (byte-identical).
6. **New verification tooling:** `glb_eval.py` (independent NumPy glTF skin/animation evaluator with pot contact), `compare_r001.py` (byte/field parity), extended `inspect_glb.py` (flag/extension inventory), `verify_reimport.py` (Blender re-import + evaluated minima), `godot_check.gd` (Godot re-skin, loops, cull modes, pot contact), `godot_shots.gd` (GPU captures), `godot_project.py` (isolated project + import settings), updated `render_previews.py`/`compose_previews.py`/`build_all.sh`.

## Deviations

- Scratch/Godot projects outside the repository (no `/tmp` access).
- Residual between-key interpolation penetration 0.36–0.38 mm in the gait clips (target ≥ −1 mm met).
- Fingertips of the right hand graze the actual pot wall by 1.3 mm (3 vertices). Not changed: altering the hand pose would move `carry_anchor`, which must stay fixed.
- With Godot's default AnimationPlayer keyframe optimizer, the imported rest clip shows −1.2 mm / 0.9 mm float; this is an import-setting effect that also applies to r001. Recommended import setting `optimizer/enabled = false` is documented and verified.
- No redesign, costume or proportion change was made.
