# WEAVE-001 r001 — provenance

Brief: `art/briefs/economy-batch8/WEAVE-001.md` (batch README `art/briefs/economy-batch8/README.md`, a proposal, not a frozen pack). Shared rules: `art/briefs/economy-batch4/README.md` (character-motion rules). Contract: `art/handoffs/bronze-bohemia-opus-v2/COMMON.md`, `RETURN.md`, kit spec 2.0 (`templates/kit-asset.json`).

All output is `provisional_reconstruction`, `scale_basis = project_fit`, `physical_dimensions_m = null`. Original-project licence: **unselected** (manager/owner decision).

## Evidence classes

| Item | Class | Basis / locator |
|---|---|---|
| Loom function at Březnice | **E (negative / unresolved)** | S-CH19 (Chvojka, Menšík, Šálková & Kuna 2019, *Archeologické rozhledy* 71: 267–308) pp. 291–293 as summarised in `content/research/economy/crafts-exchange.md` §2.3 (branch `docs/economy-research`): hole wear mostly in the lower part, classic warp-weighted suspension "rather unlikely", base-up tying hypothesised; mass weight deposits are waste, not looms in situ (pp. 270, 301). I did not re-read S-CH19 for this job. |
| Upright loom used as the work station | **R** | LOOM-001 r001 return (branch `art/loom-001-r001`, commit 54f0601), itself R throughout (`content/research/next-batch/material-culture.md` §3 "LOOM-001 — upright warp-weighted loom"). |
| Weaving as a household winter craft at an upright frame | **R** | `crafts-exchange.md` §3 "Economic process map" row "Textiles" (fibre prep → spin → weave R; loom with weights, function debated E; weaving indoors/winter R) and §4 F7 "Spinning and weaving". |
| Fibre / weft colour (undyed wool-brown) | **R** | `crafts-exchange.md` §2.3 (flax not in the Březnice crop list, E-negative; sheep unverified locally) and `subsistence.md` F10 "Milk, meat, dung and wool outputs" (wool → textile chain). The yarn colour is a design choice. |
| Technique: two-hand pass of a stick-bobbin through the natural shed, beat-up towards the fell with a sword beater, heddle-rod tug for the counter-shed | **R** | No source in the project corpus describes Bronze Age weaving technique, tools or posture. Generic warp-weighted-loom practice (weaving top-down, beating upwards) chosen to match LOOM-001's geometry. |
| Weft bobbin (0.24 m stick with wound weft) and sword beater (0.72 m wooden blade, grip, knob) | **R** | Generic tool forms; no regional find modelled. MC02 (below) shows a weft ball and a long loose stick; I kept a stick-bobbin because it reads better in the hand at village zoom. |
| Posture (~27° forward lean), stance on the idle footprints, timings (3.0 / 2.0 / 2.0 / 1.2 s) | **R** | Game-fit. The lean follows from LOOM-001 `weaver_origin` being 0.70 m in front of the loom (cloth plane 0.778 m from the character root). |
| Person identity, placement in a village | **F** | Preview staging only. |

## References viewed

- **MC02** — Wolfgang Sauber, "Museum Quintana - Webstuhl 1.jpg", Wikimedia Commons, CC BY-SA 3.0 (`content/research/next-batch/references/MC02-loom-reconstruction-quintana.jpg`, credits in `references/CREDITS.md`, branch `docs/economy-research`). A modern Bavarian museum reconstruction. I viewed it for general readability only. No pixels were copied or traced and no measurement was taken.
- MC01 (loom weights) was not needed: the weights belong to LOOM-001/LOOMWEIGHT-001 and are not part of this kit.

## Inputs and fixtures (SHA-256; full list in `checks/input_hashes.json`)

| Input | Use | SHA-256 |
|---|---|---|
| PERSON-001 r002 `model.glb` (`art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/`) | byte comparison of mesh/skin/bind pose/palette; 1.70 m scale figure in previews | f2be7a0f948e554974e2fb76aeda1fa583a8a4f4fe755c8469a0dbf46ae84706 |
| PERSON-001 r002 `source/person_001.blend` (copy in `source/fixture_PERSON-001-r002/`) | base of `person_weaving.blend` (a copy is opened; the original is untouched) | b2138f9094984ac041984d50f4694a1bc296a3f81847eb5d06f8d5cb492e7963 |
| PERSON-001 r002 `source/gen_person.py` (copy) | pose solver executed unchanged without `main()` | 61b95fd808f6ed48f1beab43299ac00b6d71985a3bb9bf1496cabef5a1d32928 |
| PERSON-001 r002 `source/person_palette.png` (copy) | palette (byte-identical inside `person_weaving.glb`) | 9f2b4fc161398577c6912e2f282bac259df02745cba90f0fd156350c6c4c22fe |
| LOOM-001 r001 `models/loom_weaving.glb` (branch `art/loom-001-r001`; copy in `source/inputs/`) | `weaver_origin`, `cloth_face`, warp/heddle geometry; preview context. Never exported. | cf379b6c21a9a67d7d6dc5d3fff370b68de1613f9a0aa9a4e82c96449659fd7e |
| POT-001, HOUSE-001 opus-v2 fixtures | village-angle context in Godot previews only | see `checks/input_hashes.json` |

The loom's warp layers, fell and heddle-rod position come from LOOM-001 r001 `source/gen_report.json` (`key_positions_gltf`, `warp_back`, `warp_front`) and `gen_loom.py` constants. The values are copied into `source/gen_weaving.py` and `source/motion_eval.py`. `weaver_origin` and `cloth_face` are read from the GLB itself in every check.

## Original work and third-party material

- `weft_bobbin.glb`, `sword_beater.glb`, their 128² atlas, the five clips and the hold nodes are original procedural project work (`source/gen_props.py`, `source/gen_weaving.py`).
- `person_weaving.glb` reuses PERSON-001 r002 mesh, rig, skin, palette and `carry_anchor` unchanged (private project material).
- No third-party media are incorporated. Fixtures and references are private project material with no public sublicence granted.
