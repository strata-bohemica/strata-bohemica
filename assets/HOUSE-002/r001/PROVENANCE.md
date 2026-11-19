# HOUSE-002 r001 — provenance

> **Proposal for scale testing, not an excavated plan.** This is a larger-footprint variant so the manager can test settlement scale. It does not reconstruct any excavated Březnice house.

## Evidence classes

| Item | Class | Basis / locator |
|---|---|---|
| Regional LBA houses assumed to be oblong, above-ground, **5–8 m wide**, with post walls and wattle-and-daub | E (as a cited model assumption, not a Březnice observation) | Kuna et al. 2022, *J. Anthropol. Archaeol.* 67:101433, p. 8 (S-KU22), via `content/research/economy/crafts-exchange.md` §2.1 (branch `docs/economy-research`) and `content/research/next-batch/settlement-features.md` K22 / open question 8. CC BY-NC-ND 4.0, so the source is linked and cited only and nothing is copied. |
| No house plans survive at Březnice; house length, door position and post layout are unknown | E (absence statement) | same locators |
| Four of five sunken storage vessels lie ~2.5 m west of long pits, read as roughly mid-house | E (site pattern) | S-KU22 p. 8 via crafts-exchange.md §2.1. This motivates interior store spots, but their positions here are F. |
| White-coated daub fragments | E | via HOUSE-001 r001 (not used here; base daub colour only) |
| Walls 10.0 × 5.5 m, eave 2.2 m, ridge 4.6 m, overhang 0.4 m, door 0.8 × 1.5 m centred on the long +Z side | R | `art/briefs/economy-batch5/HOUSE-002.md` (design values for scale testing) |
| Ridge along X; 0.18 m wattle-and-daub wall; post layout (corner, long-wall posts at x = ±1.75/±3.4, door jambs, back mid post, gable posts at z = 0/±1.4); internal ridge posts at x = ±1.75; four tie beams; 12 rafter pairs; thatch 0.22→0.36 m with turf ridge; pitch 36.4° underside | R | own design within the brief envelope. HOUSE-001 r001 material language and mesh split. |
| Anchor positions: hearth west bay, three store spots along the back wall | F/R | own placement, measured clear of posts and walls (`checks/contact_check.json`) |
| Palette and procedural textures (daub, timber, thatch/turf atlas) | R, own work | the HOUSE-001 r001 recipe (`gen_house.py`) re-implemented with seed 2002 |

Visual inspiration is inherited from HOUSE-001 r001 `references/HOUSE-REFERENCES.md` (WH01–WH07, modern reconstructions and museum models). None of those photos was re-opened for new detail here, and no pixels from them were used.

## Original vs third-party

- Geometry, generator code, textures and previews are original project work produced by the AI modelling agent. No third-party meshes, textures or photos are incorporated (`incorporated_resources: []`).
- The licence is **unselected** and remains a manager/owner decision.
- Fixtures were used read-only for scale, contact and comparison previews. They are not part of the kit and not redistributed in `models/`. The SHA-256 of every input is in `checks/input_hashes.json`:

| Fixture | Path | SHA-256 |
|---|---|---|
| PERSON-001 r002 | `art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/model.glb` | `f2be7a0f948e554974e2fb76aeda1fa583a8a4f4fe755c8469a0dbf46ae84706` |
| HOUSE-001 r001 (fixture = return) | `art/handoffs/bronze-bohemia-opus-v2/fixtures/HOUSE-001/model.glb` | `14be154b4c679230e9f8c997b8a249d04aad6646846425f4a08a44e795ccc88a` |
| POT-001 r001 | `art/handoffs/bronze-bohemia-opus-v2/fixtures/POT-001/model.glb` | `9ea20160b718577e8091c6e91134b32bbd9c6e2379285f50371b756fe35120a0` |
| KILN-001 r001 hearth_base | `art/returns/bronze-bohemia-v3/KILN-001/r001/models/hearth_base.glb` | `2e12bf68e61480642433a85b1d4c949f23b7207032adbb00fcef2cbcef631de2` |
| KILN-001 r001 hearth_open_top | `…/KILN-001/r001/models/hearth_open_top.glb` | `c13b6fe99d3921707dc4856dbad489f5118e84c7ace8690d7911324455467420` |
| KILN-001 r001 fire_lit | `…/KILN-001/r001/models/fire_lit.glb` | `b84b389c7d9892fceeb69e89aeb3f1da228a062d42df79fb46e65a36053058bc` |
| KILN-001 r001 firewood_stack | `…/KILN-001/r001/models/firewood_stack.glb` | `125cc0121e0cf5214de30af9ee2fb79da3260258db553605e1a4aec3b58c09f5` |
| STORE-001 r001 store_jar | branch `origin/art/store-001-r001` (commit `f55ff4f`), `art/returns/bronze-bohemia-v3/STORE-001/r001/models/store_jar.glb` | `2391e5deb5951ee57ae50c985a7412bbfd6c01f5e145857f51190ba168a0e23c` |
| STORE-001 r001 store_jar_sunken | same branch | `3306d9b05b91d5ec8bb718078def18af3c6510f1b223e80f04aabddab3de4226` |
| STORE-001 r001 store_jar_renewed | same branch | `3601603ebd52a90439e1f2441268164019040dbb46e8fb22f31dfc0785049e59` |

STORE-001 r001 is an unmerged **non-contract study**, and storage remains on HOLD (`content/research/next-batch/README.md`). The brief names "STORE-001 jar", so this study's jars were used only to test floor fit. The store spots are not a storage contract.

`source/inspect_glb.py` is adapted from KILN-001 r001 (same project, same agent family). The Godot `shot.gd`/`check.gd` structure follows KILN-001 r001.
