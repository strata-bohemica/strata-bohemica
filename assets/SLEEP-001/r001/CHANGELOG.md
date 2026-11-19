# SLEEP-001 r001 — changelog

## r001 (first return)

Brief: `art/briefs/economy-batch8/SLEEP-001.md` r001 (economy batch 8 proposal) + `README.md`; shared rules
`art/briefs/economy-batch4/README.md`; contract `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` / `RETURN.md`.

### Added

* `models/bed_straw.glb` — straw-stuffed sack mattress (~1.90 × 0.80 m, top 0.16 m) with a cattle hide cover and
  a rolled fleece at the head end; anchors `base_center`, `sleeper_origin`, `head_rest`, `lie_center`.
* `models/bed_hide_pile.glb` — bracken/straw heap with a large hide, two sheepskins and a folded fleece head
  rest; same sleeping-surface specification and anchors as `bed_straw`.
* `models/bedding_rolled.glb` — rolled and tied hide/fleece for storage; anchors `base_center`, `carry_grip`.
* `models/person_sleep.glb` — PERSON-001 r002 (mesh, skin, bind pose, palette, `carry_anchor` unchanged) with
  in-place clips `lie_down` (2 s), `sleep_lie` (4 s loop, one slow breath) and `get_up` (2 s).
* Shared atlas `source/textures/sleep_atlas.png` (512²), one material `SLEEP_kit`.
* Generators, editable `.blend` files, independent checks, Blender and Godot GPU previews, MP4/GIF.

### Deviations from the brief / notes

* The brief names no anchors; the beds carry `sleeper_origin` (character root for all three clips),
  `head_rest` and `lie_center`; the roll carries `carry_grip`.
* `bed_hide_pile` and `bedding_rolled` have no brief budget; self-set ≤ 300 / ≤ 200 triangles.
* The clips are in place (root fixed on `sleeper_origin`), but the body itself travels ~0.5 m back onto the bed.
* HOUSE-002 is not merged, so the demo uses HOUSE-001 only (roof off; extra preview-only wall cutaway).
* `tools/inspect_asset.py` does not know batch-8 IDs; it was not used or edited (own independent checks).
