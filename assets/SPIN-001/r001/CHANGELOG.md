# SPIN-001 r001 — changelog

## r001 (first return)

Brief: `art/briefs/economy-batch5/SPIN-001.md` r001 (economy batch 5 proposal), shared rules from `art/briefs/economy-batch4/README.md`, and the opus-v2 `COMMON.md`/`RETURN.md` contract with kit spec 2.0.

### Added

* `models/spindle_whorl.glb` (220 tris): a low-whorl drop spindle. It has a biconical clay whorl (Ø 42 mm), a 0.25 m shaft, a cop of spun yarn and a 0.10 m yarn leader. Anchors: `grip` (pinch), `shaft_top`, `base_center`.
* `models/distaff_with_fibre.glb` (174 tris): a 0.83 m stick with a lumpy undyed wool bundle and a loose drafted tuft. Anchors: `grip`, `fibre_center`, `base_center`.
* `models/fibre_basket.glb` (240 tris): a small wicker basket heaped with raw wool. Anchors: `base_center`, `pick_point`.
* `models/yarn_balls.glb` (248 tris): one cream ball, one natural-brown ball and one twisted skein. Anchor: `base_center`.
* `models/person_spinning.glb`: PERSON-001 r002 unchanged (mesh, skin, bind pose, palette, materials and `carry_anchor` byte-identical). It adds:
  * `spin_enter` (1 s, idle → spinning);
  * `spin_stand` (2 s loop: wrist flick, drafting up towards the fibre, sliding down);
  * `spin_exit` (1 s, reverse of `spin_enter`);
  * `spin_walk` (1 s loop at 0.8 m/s, spinning while walking);
  * `distaff_hold` (static, under `hand.L`);
  * `spindle_hold` (animated, under `hand.R`).
* One shared material `SPIN_kit` and one 512² procedural atlas for the four props.
* The full rebuild pipeline: generators, independent checks, an isolated Godot 4.5.1 import/check and GPU captures. All six standard stills, village-angle ortho 25/16 views, contact/culling close-ups, loop and transition sheets, and MP4/GIF.

### Deviations from the brief (all recorded in `asset.json` → `deviations`)

* **Extra clips.** `spin_enter`/`spin_exit` were added so that the character starts and ends on the r002 idle pose. The brief's loops (`spin_stand`, `spin_walk`) loop on the spinning pose and on a walking phase. This follows WORK-001 (grind_enter/grind/grind_exit) and GATHER-001 (basket_walk).
* **Animated `spindle_hold`.** The node has translation and rotation keys in every clip, so the spindle hangs plumb from the pinch, sways slightly with the hand's acceleration (≤ 9°) and spins. Godot imports these as tracks on `Skeleton3D/hand_R/spindle_hold`.
* **Distaff hold.** The distaff is held in the left fist in the crook of the forearm, with its lower end towards the left hip. This is how “distaff under left arm” was read. It keeps the shaft clear of the body (≥ 23 mm in all clips).
* **Drafted fibre strand.** The strand between the distaff bundle and the right pinch is not modelled.
* **Spin rate.** It is slowed for 30 fps readability: 4 turns per 2 s standing and 2 per 1 s walking.
* **Inspection tools.** Measurements use this return's own tools. `tools/inspect_asset.py` does not know batch-5 IDs and was not edited.
