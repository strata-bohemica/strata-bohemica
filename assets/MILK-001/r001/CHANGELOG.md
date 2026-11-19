# MILK-001 r001 — changelog

## r001 (first return)

Brief: `art/briefs/economy-batch5/MILK-001.md` (herding and milking person motions + milk vessel), batch-5 README, batch-4 shared rules, opus-v2 COMMON/RETURN.

### Delivered
- `models/milk_pail.glb` (288 tris ≤ 300; `grip`, `rim_center`, `base_center`) — ceramic pot with lugs and a cord sling.
- `models/milk_pail_full.glb` (240 tris) — alternate full state (milk surface).
- `models/herding_stick.glb` (66 tris ≤ 80; `grip`, `grip_top`, `tip`, `base_center`) — 1.40 m staff.
- `models/milking_stool.glb` (72 tris ≤ 200; `seat`, `base_center` + milking-station anchors `worker_origin`, `pail_wait`, `pail_place`, `cow_place`).
- `models/person_herding.glb` — PERSON-001 r002 byte-identical body/rig/skin/palette + clips `herd_walk` (1.0 s loop, 0.9 m/s, staff planted 0.45–0.90 s), `herd_walk_gesture` (1.0 s), `herd_idle` (2.0 s loop), `milk_enter` (2.0 s), `milk` (1.0 s loop), `milk_exit` (2.0 s); new nodes `stick_hold` (hand.R) and `pail_hold` (hand.L).
- Kit: 2 materials (`MILK001_ceramic`, `MILK001_wood`), 1 shared 512² atlas; all single-sided, opaque, no glTF extensions.
- Checks (`checks/`), Blender + Godot GPU previews incl. village ortho 25/16, contact, garment/seat, culling, loop sheets, transitions, 2 GIF + 2 MP4.

### Deviations / interpretations
- `herd_walk_gesture` is a separate phase-aligned 1.0 s clip (first/last = `herd_walk` t=0) so the gesture can be occasional; the brief listed the gesture inside `herd_walk`.
- `herd_*` loops do not start on the r002 idle pose (locomotion/stance loops, like r002 `walk`); `milk_enter`/`milk_exit` start/end exactly on it.
- `milk_pail_full.glb` added (alternate state).
- Milking placement anchors live on `milking_stool.glb`, not on the character; the stool therefore doubles as the station definition (the brief marked the stool optional).
- `pail_hold` is used only inside the documented hold windows of `milk_enter`/`milk_exit` (pail moved from `pail_wait` to `pail_place` and back); a 0.25 m pot cannot hang from the r002 idle hand without passing through the tunic.
- ANIMAL-001 `cattle.glb` has no udder; the hands target the belly underside in front of the stifles ("udder region"), 8–54 mm below it.

### Iteration notes (design history inside r001)
- Milking geometry was tuned against the actual exported cow and skinned body: cow 1.2 cm further away, hip lowered to give 1 mm seat contact, left foot moved off the cow's hind hoof, pail wait spot moved from the milker's side to in front of the toes (the side route crossed the left shin), head/neck pitched back so the head stays ≥ 11 mm off the flank.
- Staff moved 3.6 cm outward (it touched the right upper arm), tip lifted by the end-cap rim drop so no bark goes below the floor, gesture redesigned (first version passed the staff through the legs) and slowed (peak 16°/key).
- Pail-hold binding frame fixed to a whole key; a teat-reach blend snap (26°/key) removed.
