# HOUSE-002 r001 — changelog

## r001 (first return)

- **Brief:** `art/briefs/economy-batch5/HOUSE-002.md`, a regional-size longer house variant. Economy batch 5 is a proposal backlog, not a frozen pack. The shared rules come from `art/briefs/economy-batch4/README.md`, and the contract is `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` + `RETURN.md` (kit spec 2.0).
- **Delivered:** `models/house_002.glb`. It has 2804 triangles, 3 materials (Daub, Timber, Thatch), 1024/512/1024 px embedded textures and the mesh nodes `Wall`, `Frame`, `Roof`, `DoorRecess`. The Roof node is separable. Anchors are `entry`, `door_inside`, `label_anchor`, `interior_center`, `hearth_spot` and `store_spot_1..3`.
- **Envelope:** walls are 10.0 × 5.5 m outer and 0.18 m thick. Eave 2.2 m, ridge 4.6 m, roof envelope 10.80 × 6.30 m. The 0.80 × 1.50 m door is centred in the +Z long wall. Two internal ridge posts stand at x = ±1.75.
- **Evidence:** six standard stills, roof on/off views, both roof slopes, interior views with PERSON r002, KILN-001 hearth and STORE-001 jars at the anchors, and the HOUSE-001 comparison at ortho 25/16. There are also contact and culling close-ups and a three-house repeat demo, all from real Godot 4.5.1 OpenGL GPU captures plus Blender stills.

### Deviations / design decisions

1. The return has one kit GLB with a separable `Roof` node, as HOUSE-001 does. There are no separate roof and shell GLBs. Roof-off means hiding node `Roof`, and the rafters stay in `Frame`.
2. An extra anchor, `door_inside` (0, 0, 2.2), was added for paths through the door.
3. The daub texture tile is 5 m instead of HOUSE-001's 4 m, so the foot band never wraps up to the 4.27 m gable apex. The band stays 0.30 m.
4. The store spots have a yaw of 180° so that STORE `worker_origin` points into the room. The hearth spot has yaw 0, so KILN anchors work unchanged.
5. The optional second door or gable door was not modelled.
6. There is no floor mesh and no door leaf, as in HOUSE-001.
7. The 1.50 m door is lower than the 1.70 m PERSON. The contact section shows the head above the lintel line at `door_inside`, so the game must accept a stoop or clipping during the door transition. This is the brief value and was not changed.
8. STORE-001 fixtures came from the unmerged branch `origin/art/store-001-r001` (non-contract study).
9. During iteration, thatch-top vertex jitter was reduced to ±0.012 m. Larger dips caused small dark self-shadow notches near the eave in Godot (visible in the first GPU pass, fixed before return).
