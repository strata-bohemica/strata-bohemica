# KILN-001 r001 — CHANGELOG

## r001 (2026-11-06) — first return

**Brief:** this follows the DRAFT brief "KILN-001 r001 — fired-earth hearth/oven feature" in `content/research/next-batch/settlement-features.md` §6. It also uses the §3 KILN-001 notes, the §3 WOOD-001 note (firewood dressing) and `content/research/next-batch/README.md`. The brief is a research proposal and not a frozen pack. It is delivered as though it belonged to the opus-v2 pack, using `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` and `RETURN.md` with kit metadata spec 2.0.

### Delivered

- **Required GLBs (5):**
  - `models/hearth_base.glb`
  - `models/hearth_open_top.glb`
  - `models/hearth_dome_top.glb`
  - `models/fire_embers.glb`
  - `models/fire_lit.glb`
- **Optional extra (1):** `models/firewood_stack.glb`, the WOOD-001 dressing requested by the assignment.
- **Anchors:** `base_center`, `fire_center`, `pot_rest` and `tend_origin` (all required), plus `firewood_spot`. The anchors are exported as named empty nodes with identical values on the base and on both tops.
- **Materials and texture:** two materials for the whole kit (`KILN_earth`, `KILN_glow`) and one 512² procedural atlas. All materials are opaque and single-sided, and the kit uses no glTF extensions.
- **Source and rebuild:**
  - reproducible generator and native `.blend`;
  - two-run determinism check;
  - `.blend` re-export check;
  - independent GLB parser, Blender re-import, BVH contact check;
  - Godot 4.5.1 import probe and GPU captures.

### Design iterations (all from viewing the actual GPU renders)

1. **Dome mouth.** In the first renders the dome mouth (0.36 m) was unreadable from the village camera. I widened it to a splayed opening, about 0.41 m clear at the floor and 0.37 m high. The dome was also moved 0.10 m behind `base_center`, so the shared `fire_center` sits just behind the mouth.
2. **Fire beds.** The ember beds became ellipses that reach the mouth, so the embers and lit states show through it.
3. **Base profile.**
   - Per-segment smoothstep caused terracing; it was replaced with a linear profile.
   - The outer edge was lowered to 2 mm above y0 to remove the visible "plate" step.
   - The fired-red and dome colours were desaturated.
4. **Mesh fixes.**
   - The boolean mouth originally produced 4 non-manifold edges. The fix was an odd arch-segment count and meridians offset from x=0; the export is now closed and outward.
   - Flames were rebuilt as curved 5-sided tongues; they had looked like crystals.
   - Stones were made larger and darker.

### Deviations from the draft brief

- **D1 `tend_origin`.** The draft gives (0, 0, −0.8). With +Z front, the dome mouth faces +Z, and a tender behind the oven could not reach it. The anchor is therefore (−0.30, 0, 0.78), yaw 158.96°, facing `fire_center`. This also keeps the mouth unobstructed from the (18, 18, 18) village camera. The manager can move it in `gen_kiln.py` (`TEND`).
- **D2 Firewood.** The `firewood_spot` anchor and `firewood_stack.glb` were added as optional dressing.
- **D3 Dome offset.** The dome is offset 0.10 m toward −Z relative to `base_center`. The anchors and `fire_center` stay identical for both tops.
- **D4 Motion study.** The optional `person_tending.glb` motion study (`tend_enter`/`tend`/`tend_exit`) was **not** produced. The assignment's deliverable list did not require it, and a skinned-clip study needs the full PERSON source workflow (as in WORK-001). The PERSON r001 fixture is shown standing on `tend_origin` only. Because the kit has no motion, there is no GIF/MP4.
- **D5 Base skirt.** The base has a hidden skirt down to y = −0.03, so its export bounds min y is −0.03. Its visible top surface stays above y0, at ≥ 0.002 m.
- **D6 Godot textures.** Godot's default GLB import extracts the embedded atlas once per GLB, giving 6 identical 512² PNG copies. The GLBs stay self-contained as the contract requires. Deduplication is an integration choice for the manager.
