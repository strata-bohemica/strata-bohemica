# MEAL-001 r001 — provenance

Job: cooked-food contents and serving props (economy batch 5, `art/briefs/economy-batch5/MEAL-001.md`, proposal pack). Contract: `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` + `RETURN.md`, kit spec 2.0. All output is `provisional_reconstruction`, `scale_basis = project_fit`, `physical_dimensions_m = null`.

## Evidence classes

| Item | Class | Source / locator | What it does and does not support |
|---|---|---|---|
| Crops at Březnice: broomcorn millet, barley, emmer/einkorn/spelt/free-threshing wheat, lentil, pea, faba bean | **E** (site level) | `content/research/economy/subsistence.md` §2.2, citing S22 p. 6 (Results) and SP23 §3.1 / §4.1 | Shows these crops were present (charred). It does not show any dish, recipe, proportion or season. Used only to choose plausible colours: a cream millet/groats porridge and a brown stew with lentil-orange, pea-green and faba-brown pieces. |
| Cereal and legume starch on grinding slabs; boiled-meat proteins in samples | **E** | subsistence.md §2.5 (SP23 §3.3–3.5 pp. 8–9; K22 p. 10) | Shows processing and cooking happened. It does not describe a food surface. No meat was modelled. |
| Porridge, pulse stew, flour flatbread/dough as game meals | **R/F** | subsistence.md §2.5 "R (game diet)" and §4 F5 ("Dishes are R/F") | These are the meal types the game asks for. Recipes and proportions are F/R. |
| Flat breads, no oven | **R** | subsistence.md §2.5: "no bread oven is evidenced here, and the O-pec features are unresolved"; brief: "No bread ovens claimed." | Modelled as generic unleavened griddle/hearth-stone breads. No oven is implied. |
| Water in a pot | **R** | F5 inputs (water + fuel); COMMON.md water rule | An opaque stylised surface, not a shader effect. |
| Wooden spoon, ladle | **R** | brief ("R, `grip`") | No wooden utensil from the site is cited. Forms and sizes are generic. |
| Fill levels, lumps, colours, sizes | **R** | design choices fitted to the host vessels | Game readability only. |
| Pot set into the ember bed, ladle resting in the stew pot, spoon in a bowl, people holding bowls | **F/R** | preview placement | Not evidence of cooking technique or eating posture. |

## Original work and third-party inputs

- All meshes, the 256×256 atlas (procedural numpy noise and dots, seed 5001) and all scripts are original work generated for this job. No photographs, scans or third-party pixels were used, and no third-party media was incorporated (`incorporated_resources: []`).
- Licence: unselected original project work. The decision is for the manager/owner.
- Scale/contact fixtures and accepted returns were **read and copied only, never modified**. They are used for fitting, contact checks and previews:

| Input | SHA-256 |
|---|---|
| `art/handoffs/bronze-bohemia-opus-v2/fixtures/POT-001/model.glb` | `9ea20160b718577e8091c6e91134b32bbd9c6e2379285f50371b756fe35120a0` |
| `art/handoffs/bronze-bohemia-opus-v2/fixtures/POT-001/asset.json` | `2361eb662a3cddc040881d136bbc74c0b7561db234dc1d22730605143ba3f114` |
| `art/handoffs/bronze-bohemia-opus-v2/fixtures/HOUSE-001/model.glb` | `14be154b4c679230e9f8c997b8a249d04aad6646846425f4a08a44e795ccc88a` |
| `art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/model.glb` | `f2be7a0f948e554974e2fb76aeda1fa583a8a4f4fe755c8469a0dbf46ae84706` |
| `art/returns/bronze-bohemia-v3/POTTERY-003/r001/models/bowl.glb` | `fada4401af0a20396e2626919aab97de66842077871c3b57edd8b939088ababa` |
| `art/returns/bronze-bohemia-v3/KILN-001/r001/models/hearth_base.glb` | `2e12bf68e61480642433a85b1d4c949f23b7207032adbb00fcef2cbcef631de2` |
| `art/returns/bronze-bohemia-v3/KILN-001/r001/models/hearth_open_top.glb` | `c13b6fe99d3921707dc4856dbad489f5118e84c7ace8690d7911324455467420` |
| `art/returns/bronze-bohemia-v3/KILN-001/r001/models/fire_embers.glb` | `c9dfda43f5390b5fb305fcf36ad167fa0cf2062000eeb3b21267fdb37b9a5a82` |
| `art/returns/bronze-bohemia-v3/KILN-001/r001/models/firewood_stack.glb` | `125cc0121e0cf5214de30af9ee2fb79da3260258db553605e1a4aec3b58c09f5` |

The full input record, including the brief, contract, template, the batch-4 README (PR #30 checkout) and the economy research files (branch `docs/economy-research` checkout), is in `checks/input_hashes.json`.

## How the measured values were obtained

- **POT-001 inner wall:** 22 segments, vertices at ±8.18° from +Z. Neck minimum inner radius 0.133–0.1343 m at y ≈ 0.398. Rays and vertex rings were taken from the fixture GLB during set-up, and `fit_check.py` re-verifies the fit in every build.
- **POTTERY-003 bowl inner wall:** 20 segments, a vertex on +Z. Inner radius 0.0962 m at y 0.058 and 0.1049 m at y 0.0785. Wall 5 mm.
- **KILN-001 open hearth:** `fire_center` (0, 0.010, 0) and `pot_rest` (0.82, 0, 0) were read from the GLB anchors.
- **Hold pose:** the POTTERY-003 r001 two-hand rule (palm midpoints from bones `hand.X` and `fingers.X`), applied to the PERSON r002 fixture's own `work` clip at t = 0.
