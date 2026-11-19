# HIDE-001 r001 — changelog

## r001 (first return)

Brief: `art/briefs/economy-batch8/HIDE-001.md` + `art/briefs/economy-batch8/README.md` (proposal, not a frozen pack); shared rules `art/briefs/economy-batch4/README.md`; contract `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` / `RETURN.md`, kit spec 2.0.

Added:

- `models/hide_frame.glb` (468 tris): leaning pole frame with a laced raw hide (flesh side +Z with a scraped band, hair side behind, 8 mm thick), 16 rawhide thongs, lashed corners, rear braces. Anchors `base_center`, `worker_place`, `scrape_zone`, `hide_center`.
- `models/hide_drying_rack.glb` (424 tris): forked posts, pole, a scraped hide and a dried leather piece draped over it. Anchors `base_center`, `hang_point`.
- `models/scraper_bone.glb` (128 tris): two-grip bone scraper with a broad convex edge. Anchors `grip` (brief), `edge_mid`, `base_center`.
- `models/leather_bundle.glb` (92 tris): rolled leather with spiral ends and two thong ties. Anchors `base_center`, `carry_grip`.
- `models/person_hide.glb`: PERSON-001 r002 (byte-identical mesh/skin/bind/palette/materials/`carry_anchor`) with `scrape_enter` (1.2 s once), `scrape_hide` (2.0 s loop, two downward strokes), `scrape_exit` (1.2 s once); `scraper_hold` under `hand.R`; `frame_place`, `bundle_place`, `rack_place` on the rig root.
- One shared 512² procedural atlas and one single-sided opaque material (`HIDE001_kit`) for all four props.
- Full check set (`checks/`), Blender and Godot GPU previews, GIF/MP4 (`previews/`), reproducible sources (`source/`).

Deviations from the brief (also in `asset.json` → `deviations`):

- Two one-shot clips (`scrape_enter`, `scrape_exit`) are added around the requested loop so that the character starts and ends on the r002 idle pose (batch-4 character rule).
- The drying rack uses the 500-triangle frame budget, not the 150-triangle "small" budget.
- Placement nodes are exported on the character (and the inverse `worker_place` on the frame).
- The scraper's edge is keyed 0.8 mm above the hide (measured gap 0.4–0.8 mm while stroking, ≤ 12 mm on the return).
- The scraper is held in both fists: the right fist carries it (`scraper_hold`), the left fist is solved onto the mirrored grip and is not attached.

Iteration notes (before this return; no earlier revision exists): the worker distance was moved from 0.24 m to 0.30 m and `scrape_enter` was given a "ready" hold close to the body, because the first version swept the hanging scraper through the hide plane (up to 99 mm) while the arms rose; the final measured minimum gap in `scrape_enter`/`scrape_exit` is +0.8 mm. The scraper blade was redesigned with narrow grips and a broad edge so the fists stay ≥ 18 mm off the hide.
