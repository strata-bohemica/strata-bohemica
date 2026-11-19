# BRONZE-001 r001 — provenance

All output is `provisional_reconstruction`, `scale_basis = project_fit`, `physical_dimensions_m = null`. Original-project licence: **unselected** (manager/owner decision). Historical acceptance is separate from this technical return.

## Evidence classes

| Part | Class | Basis / locator |
|---|---|---|
| Bronze tools exist in the regional Late Bronze Age (winged and socketed axe heads) | E (regional only) | WM01 `art/handoffs/bronze-bohemia-v1/references/WM01-pottery-tools.jpg` (Robčice/Malinec hoard, Milavce group, western Bohemia); MC12 `content/research/next-batch/references/MC12-winged-axe-hallein.jpg` (winged axe with loop, Salzburg, Urnfield) |
| Knife form (slightly curved blade, ring-ended tang) | E (regional only) | MC08 `content/research/next-batch/references/MC08-razor-knives-milavce.jpg` (Milavce knives and razors, 1250–950 BC); MC09 shows a knife only — its flanged axe is an earlier type and was **not** used |
| Bronze at Březnice | E (local, negative) | Only one sherd with a melted-on bronze droplet (S-ZEN DTB2, 2006_O_06; `content/research/economy/crafts-exchange.md` §2.6). No bronze tool type is verified at the site. |
| Tools scarce, shared, recycled; small shared tool pool | R synthesis | `crafts-exchange.md` §2.6 (bullets “R — Synthesis for the game”, S-KM20, S-RA19, S-KR24); brief `art/briefs/economy-batch4/BRONZE-001.md` |
| Firewood as an axe use | E for fuel need, R for the tool | `subsistence.md` resource table row “Firewood … axe (regional, not verified here)” (S22 p. 10) |
| Head type “winged”, head length 0.164 m, edge width 0.053 m, wings folded round the haft foot, lashing over the wings | R | Proportions informed by WM01/MC12 by eye; not traced, not measured; draft design values 0.16 m / 0.05 m from `material-culture.md` §5 |
| Knee-shaped wooden haft, 0.665 m total, wood species | R | Hafts do not survive; form is a common European reconstruction choice, not attested at Březnice |
| Knife handle plates (organic) and ring end | R | MC08 by eye |
| Scrap state (broken wing part + blade fragment, greener patina) | R | Generic break for the recycling loop (crafts-exchange §2.6) |
| Chopping block, split pieces, chips | R | Generic |
| Chop / fell technique, stance, timing, two-handed grip, cut height 0.85 m | R | No source on posture; game readability |
| Who chops, where; oak as felling target | F | Demo placement only |

## Original vs. incorporated inputs

- **Original (this job):** `bronze_common.py`, `gen_props.py`, `gen_chopping.py` and the check/preview scripts; the procedural atlas `textures/bronze001_atlas.png` (seeded noise, no photo pixels); all GLBs, clips and previews.
- **Adapted project tooling:** `inspect_glb.py`, `verify_reimport.py`, `input_hashes.py`, the Godot helper scripts and the structure of `contact_check.py`, `render_previews.py`, `compose_previews.py` and `godot/*.gd` were adapted from the accepted WORK-001 r001 return (`art/returns/bronze-bohemia-opus-v2/WORK-001/r001/source/`, private project material).
- **Character:** PERSON-001 r002 (`art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/`): body, UVs, weights, skeleton, bind pose, materials, palette and `carry_anchor` are copied **byte-identical** (see `checks/glb_inspect.json → fixture_comparison`). Only the five r002 actions were removed in a copy, six new clips were keyed with the unchanged r002 solver and one node (`axe_hold`) was added under `hand.R`.
- **Preview-only fixtures (not in any returned GLB):** PERSON r002 standing idle, POT-001, HOUSE-001 (`art/handoffs/bronze-bohemia-opus-v2/fixtures/`), VEG-001 `oak_winter.glb`, KILN-001 `firewood_stack.glb`, `hearth_base.glb`, `hearth_dome_top.glb`. They are copied into throwaway scenes only.
- **Reference images:** viewed for proportions only; no pixels copied. MC08/MC09/MC12 are CC BY-SA 4.0 Commons photos (authors Zde, Zde, NearEMPTiness per the register in `content/research/next-batch/material-culture.md` §4; file pages and revisions in `content/research/next-batch/references/MCregistry.json`); WM01 per the v1 pack. Links are not permission to copy pixels and none were copied.
- No third-party meshes, textures or animation data are incorporated.

## Input hashes (SHA-256)

| Input | SHA-256 |
|---|---|
| `art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/model.glb` | `f2be7a0f948e554974e2fb76aeda1fa583a8a4f4fe755c8469a0dbf46ae84706` |
| `…/PERSON-001/r002/source/person_001.blend` (= `source/fixture_PERSON-001/source/person_001.blend`) | `b2138f9094984ac041984d50f4694a1bc296a3f81847eb5d06f8d5cb492e7963` |
| `…/PERSON-001/r002/source/gen_person.py` (= copy) | `61b95fd808f6ed48f1beab43299ac00b6d71985a3bb9bf1496cabef5a1d32928` |
| `…/PERSON-001/r002/source/person_palette.png` (= copy) | `9f2b4fc161398577c6912e2f282bac259df02745cba90f0fd156350c6c4c22fe` |
| MC08-razor-knives-milavce.jpg | `caac87c8729a7b358b771d668051e3e0b593c0c548d74e908685d6624a6f1797` |
| MC09-bronze-tools-prague.jpg | `17a1fa1ab930c56f3d649f044ef1376df8bfd6dd770d566ed24c94788e2459df` |
| MC12-winged-axe-hallein.jpg | `0af2510856fcb275fc2a6aa8ec935a8c1af06e9418d6301ab70cdfef2f3cfcee` |
| WM01-pottery-tools.jpg | `aad56408cec3de5512e1495acaee2697a32b268d7c1c72719911ba0af5a5acba` |

The remaining preview fixtures (POT, HOUSE, VEG-001 oak, KILN-001 pieces) are hashed in `checks/input_hashes.json`.

## Boundaries

- The knee-haft, the winged type and all dimensions are **not** attested at Březnice; do not present them as local finds.
- Hoard objects may not represent tools in daily use.
- The scrap state does not claim a local casting or recycling practice.
