# COOK-002 r001 — provenance

Job: COOK-002 r001, cooking and serving motions (`art/briefs/economy-batch8/COOK-002.md` + `README.md`, a proposal and not a frozen pack). Shared rules: `art/briefs/economy-batch4/README.md` (branch `docs/economy-batch4-briefs`). Contract: `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` + `RETURN.md`, kit spec 2.0.
Status: draft technical return. Historical approval and licensing stay with the manager/owner.

## Evidence classes

| Item | Class | Basis |
|---|---|---|
| Cooking in vessels | **E** (cite only) | `content/research/economy/subsistence.md` §2.5: boiled-meat proteins on artefact surfaces and long-pit soil (K22 p. 10, citing Pavelka 2021); `crafts-exchange.md` line 60 (same source). |
| Cereals and legumes processed for food | **E** (cite only) | `subsistence.md` §2.5: grinding-slab starch of grasses, wheat, cf. einkorn and Fabaceae (SP23 §3.3–3.5). This is why the pot holds the MEAL-001 *pulse stew* fill. |
| Recipes, pulse stew, porridge | **R** | `subsistence.md` F5 (meal types; BV-029 cooking, BV-033 fuel, POTTERY-003 bowls, KILN-001 hearth). |
| Hearth superstructure (open stone ring) | **R** | KILN-001 r001; `content/research/next-batch/settlement-features.md` (feature class "pec" is E; superstructure and use are R). |
| Crouching posture, stirring with a ladle, feeding sticks one at a time, ladling into a bowl held by a second person, timing | **R** | Design reconstruction for game readability. No source establishes posture, tools or serving practice. |
| Kindling size, stirring-stick form, pile layout, bowl height 0.70 m (brief value), receiver position | **R** | Design values. |
| Who cooks and serves, portions, schedule | **F** | Game rules; the simulation clock drives the clips. |

All output is `provisional_reconstruction`, `scale_basis = project_fit`, and `physical_dimensions_m = null`.

## Sources read (exact locators)

- `content/research/economy/subsistence.md` (branch `docs/economy-research`, commit `d8918fd`, blob `1f65f34`): §2.5 "Grinding and food preparation" (lines 130–182) and F5 "Meal types" (lines 438–457).
- `content/research/economy/crafts-exchange.md` (same branch, blob `0d53fc5`): line 60, cooking in vessels.
- `content/research/next-batch/settlement-features.md` (in this checkout): KILN-001 entries (lines 34, 59–64, 164–168). Line 64 lists "PERSON (crouch/tend clip …)" as a hearth dependency.
- `content/research/next-batch/material-culture.md`: HEARTH-001 fire-dogs (lines 233–239). These were **not** used: the item is regionally remote and ritual-loaded.
- No reference images are cited by this brief. None were used.

## Original work (this return)

- `source/gen_cooking.py`: six new in-place clips on the frozen PERSON-001 r002 rig, three hand nodes and seven placement nodes.
- `source/gen_props.py`: `fire_stick.glb`, `stirring_stick.glb` and the 64 px atlas `source/textures/cook002_atlas.png` (procedural colour cells).
- `source/cook_common.py`: layout constants.
- All check, preview and composition scripts in `source/` and `source/godot/`.
- All previews were rendered by these scripts from the exported GLBs: Blender Workbench stills and Godot 4.5.1 GPU captures. Only captions and tiling were added afterwards.

## Incorporated / referenced project material (private, no public sublicence)

| Material | Use | Modification | SHA-256 |
|---|---|---|---|
| PERSON-001 r002 `model.glb` | Byte comparison and the 1.70 m scale figure in previews | none | `f2be7a0f948e5549…` |
| PERSON-001 r002 `source/person_001.blend`, `gen_person.py`, `person_palette.png` | Copied into `source/fixture_PERSON-001_r002/source/`. The rig, body, skin and palette are the base of `person_cooking.glb`; the r002 solver is executed unchanged. | In the copy loaded by the generator, the r002 actions are removed and new actions and nodes are added. The copied files themselves are byte-identical (`checks/input_hashes.json`). | `b2138f90…`, `61b95fd8…`, `9f2b4fc1…` |
| MEAL-001 r001 `ladle.glb`, `pot_fill_pulse_stew.glb`, `bowl_fill_stew.glb` (branch `art/meal-001-r001`, commit `081b958`) | Byte-identical reference copies in `source/ref_MEAL-001/`. They are used for the grip and placement geometry, the checks and the previews. The measured ladle rest placement in POT-001, t (0.05639, 0.33305, −0.05639) and q (0.424538, −0.339888, 0.17585, 0.820561), becomes `ladle_rest`. The measured pot seat on `hearth_open_top` (base y 0.0143) becomes `pot_place`. | none (not re-exported) | `72c29782…`, `422044e2…`, `7ec8ae54…` |
| KILN-001 r001 `hearth_base`, `hearth_open_top`, `fire_embers`, `firewood_stack` (`fire_lit` hashed, not placed) | Read-only, in check and preview scenes | none | `checks/input_hashes.json` |
| POT-001 fixture, POTTERY-003 r001 `bowl.glb`, HOUSE-001, VEG-001 (oak_summer, hazel_leafed, grass_wet) | Read-only, in check and preview scenes | none | `checks/input_hashes.json` |

The full hashes of every input and copy are in `checks/input_hashes.json`. Branch documents are identified by git blob id.

## Licence

Own work: unselected original project work. The licence is a manager/owner decision; no public licence is granted here. No third-party media is included.
