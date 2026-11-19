# MEAL-001 r001 — changelog

## r001 (first return)

Brief: `art/briefs/economy-batch5/MEAL-001.md` (economy batch 5 proposal), with the shared rules in `art/briefs/economy-batch5/README.md` and `art/briefs/economy-batch4/README.md`. Contract: opus-v2 COMMON/RETURN, kit spec 2.0.

**Delivered.** All eight required GLBs:

- `pot_fill_porridge.glb`, `pot_fill_pulse_stew.glb` and `pot_fill_water.glb` (fitted to POT-001 r001)
- `bowl_fill_porridge.glb` and `bowl_fill_stew.glb` (fitted to the POTTERY-003 r001 bowl)
- `flatbread_stack.glb` (3 breads)
- `wooden_spoon.glb` and `ladle.glb`, each with a `grip` anchor

Budgets: 116–132 triangles each (limit 150). Kit: 2 materials (`MEAL_moist`, `MEAL_matte`) sharing one embedded 256² atlas. All materials are OPAQUE with `doubleSided` false, and no glTF extensions are used.

**Fill inserts.** Each fill is a closed lens solid. Its rim ring is buried 1.0–5.5 mm into the host wall at any yaw, which is what prevents gaps and z-fighting. Its origin is the host's base_center, so the placement transform is identity.

**Placements.** `fit_check.py` writes these to `source/placements.json`:

- spoon resting in a porridge bowl
- ladle resting in the stew pot
- POT-001 seated in the KILN-001 open-hearth ember bed

**Demo.** Godot GPU renders at ortho 25, 16 and 4, plus close-ups. The scene has:

- a porridge pot in the KILN-001 `hearth_open_top` ember bed
- a stew pot with a ladle on `pot_rest`
- a water pot
- two PERSON r002 holding POTTERY-003 bowls (stew; porridge with a spoon), using the POTTERY-003 hold rule
- bread, a bowl, a spoon and a ladle on the ground

**Deviations.** These are also listed in `asset.json` under `deviations`:

- **D1:** Fill origin is the host vessel's base_center, not the fill's own lowest point. This makes the identity placement exact.
- **D2:** Extra anchors were added: `host_base_center`, `fill_rim_center`, `fill_surface`, `base_center`, `stack_top`, `scoop_center`, `cup_base`.
- **D3:** No `person_<activity>.glb`. No new motion was needed: the hold samples r002's existing `work` clip, as POTTERY-003 r001 did. There is therefore no GIF/MP4.
- **D4:** The ladle is authored in a two-point floor-rest attitude (tipped −20.3° about X). It is a static pose and could roll under physics.
- **D5:** `tools/inspect_asset.py` was not used or edited; independent checks are in `checks/`.
