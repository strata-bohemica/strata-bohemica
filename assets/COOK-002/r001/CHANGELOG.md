# COOK-002 r001 — changelog

## r001 (first return)

Brief: `art/briefs/economy-batch8/COOK-002.md` (economy batch 8, proposal). The brief asks for `person_cooking.glb` (PERSON r002 + `stir_crouch`, `tend_fire`, `serve_ladle`, `cook_enter`, `cook_exit`; nodes `ladle_hold`, `stick_hold`), optional `fire_stick.glb` and `stirring_stick.glb` (≤ 80 triangles each), ladle tip to pot interior distances at 16 samples, and a GPU GIF/MP4 with the actual hearth and pot.

### Delivered

- `models/person_cooking.glb`: the PERSON-001 r002 body, rig, skin, palette and `carry_anchor`, all byte-identical, with:
  - six in-place clips:
    - `cook_enter` 2.0 s
    - `stir_crouch` 2.4 s loop
    - `tend_fire` 3.2 s loop
    - `serve_ladle` 2.0 s
    - `cook_exit` 2.0 s
    - `serve_receive` 2.0 s (added, for the second actor)
  - hand nodes `ladle_hold` (hand.R), `stick_hold` (hand.L) and `bowl_hold` (hand.L);
  - placement nodes `hearth_place`, `pot_place`, `ladle_rest`, `kindling_place`, `stick_drop_place`, `receiver_place` and `serve_bowl_place`.
- `models/fire_stick.glb` (68 triangles) and `models/stirring_stick.glb` (68 triangles). They share one opaque single-sided material and a 64² atlas.
- Checks: GLB parse, Blender re-import, reopen/re-export, determinism, contact over every key, the 16-sample ladle-tip table, Godot import with loop/optimizer settings (two configurations), Godot vs Blender cross-check.
- Previews: Blender front/side/back/top/isometric/wireframe; Godot GPU village views at ortho 25 and 16 (grid and clean); close and contact views; culling views; loop sheets; transition and serve sheets; one MP4 and one GIF (enter → stir ×2 → tend → serve with the second actor → stir → exit).

### Design decisions and deviations (R)

1. **"bowl held by a second actor at 0.7 m"**: the bowl base is at 0.70 m above the floor. The second actor (`receiver_place`, 0.90 m from the cook root) bows slightly over bent knees to hold it there. A `serve_receive` clip is added to the same GLB so the holder uses the same rig. It starts and ends on a bowl-holding pose, not on r002 idle; the game blends in and out of it.
2. `stir_crouch`, `tend_fire` and `serve_ladle` share one crouch base pose at t = 0 and at their end, so the game can switch between them at any loop boundary. `cook_enter` and `cook_exit` connect that pose to r002 idle t = 0 (0.0° / 0.0 m seams).
3. The ladle at rest is MEAL-001's measured rest pose in POT-001, with the handle on the lip. The pot is turned 59° on `pot_place` so the handle points to the cook's right hand. This pose is also the held ladle pose at `stir_crouch` t = 0, so the swap between `ladle_rest` and `ladle_hold` at the grab (1.60 s into `cook_enter`, 0.40 s into `cook_exit`) has no jump.
4. The pot stands on the fire at MEAL-001's measured seat. `fire_embers` is used under it, because the `fire_lit` flames (0.39 m high) would pass through a pot standing on the fire.
5. The kindling lies at the cook's left, outside the hearth base, with the fire ends pointing away from her. The top stick is picked with the palm down and fed between the stones under the pot in a hammer grip (fire end on the little-finger side). The pile is not depleted in the previews; the fed stick is hidden on release (game toggle).
6. The ladle grip is rigid: the handle runs straight across the palm, the cup is on the little-finger side, and the MEAL-001 `grip` anchor sits in the palm. A 25° diagonal grip was tried and rejected: it pushed the handle end through the fingers by up to 23 mm. The elbow pole follows the hand direction to keep the wrist straight.
7. Only the six new clips are exported, as WORK-001 `person_grinding` and SHEAR-001 `person_pluck` did. The r002 clips remain in PERSON-001.

### Iterations during the job (from measured checks)

- The crouch was lowered (pelvis 0.50 → 0.44 m) and the lean raised (40 → 44°) because the arm reach failed. The stirring circle was reduced (0.06 → 0.04 m) for the same reason.
- `tend_fire`: the head came too close to the pot, so the trunk turns and rolls left during the reach (lean +20°, roll −28°, twist +30°). The pick curl (36°) and palm gap (46 mm) were set so the fingers stay above the floor and do not cut into the stick.
- `serve_ladle`: the bowl and receiver were moved out (bowl at x −0.50, z 0.58) after the cook's upper arm hit the bowl. The pour was set to 48°, the lift tilt to +5°, and rim-clearing keys were added, all checked against ladle–forearm, ladle–pot and ladle–bowl penetration.
- `cook_enter`: the open hand approaches the resting handle from its palm side and above, so it does not sweep through the handle.
