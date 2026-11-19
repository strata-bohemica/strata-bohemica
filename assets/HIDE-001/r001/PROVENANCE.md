# HIDE-001 r001 — provenance

Job: HIDE-001 r001 hide processing, economy batch 8 (`art/briefs/economy-batch8/HIDE-001.md` + `README.md`; proposal, not a frozen pack). Shared rules: `art/briefs/economy-batch4/README.md` (branch `docs/economy-batch4-briefs`). Contract: `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` and `RETURN.md`, kit spec 2.0. All output is `provisional_reconstruction`, `scale_basis = project_fit`, `physical_dimensions_m = null`.

## Evidence classes

| Item | Class | Basis / locator |
|---|---|---|
| Hide and leather as household animal outputs | R | `content/research/economy/subsistence.md` (branch `docs/economy-research`, blob `1f65f34e`) §3.2 process table, row "Milking, slaughter: animals → milk, meat, hide" (scheduling marked R there); seasonal calendar row "Autumn … slaughter of surplus animals (R)". |
| No local organic evidence | E (negative) | `content/research/economy/crafts-exchange.md` (blob `0d53fc56`) §2.5 "Stone, bone, leather": bone/antler/leather not recoverable locally (acid soil). The brief repeats it: "hide/leather use regional/general R (no local organics survive)". |
| Bone tools as everyday household work | R (regional, cited second-hand) | `crafts-exchange.md` §2.5: Polish LBA bone tools from quick knife-made awls "very likely by anyone" (S-BA26 pp. 25–26, as cited there). Not read in the original here; it does not establish scraper form. |
| Stretching frame (two side poles, two lashed bars, rear braces), lacing with thongs, ~1.5 × 1.2 m | R | Brief size; construction is a generic game-fit reconstruction. |
| Bone scraper form (split long bone / rib, two grips, broad convex edge) | R | Not attested locally; shape chosen for readability and a two-handed stroke. |
| Downward two-handed scraping stroke, posture, timing (2.0 s loop, two strokes) | R | Design values in `source/hide_common.py` and `source/gen_scrape.py`. |
| Drying rack (forked posts, pole), draped scraped hide and dried leather piece | R | Game-fit dressing. |
| Rolled, thong-tied leather bundle | R | Game-fit; no tanning method is modelled or implied. |
| Who processes hides, when and how much | F | Game rules, not part of this return. |

No external or third-party media was used. No web images were viewed or copied; no reference images are cited by the brief.

## Original work and inputs

- Original project work (licence explicitly **unselected**, manager/owner decision): `source/gen_props.py`, `source/gen_scrape.py`, `source/hide_common.py`, all check/preview scripts, the procedural atlas `source/textures/hide001_atlas.png` (seeded numpy noise, no external pixels), the four prop GLBs, the three new clips and the four new nodes of `person_hide.glb`, and all previews. The check and Godot scripts are adapted from this project's earlier returns (SHEAR-001 / WORK-001 tooling pattern).
- Private project inputs (no public sublicence granted), used read-only:
  - PERSON-001 r002 (`art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/`): `model.glb` for scale/fixture comparison; `source/person_001.blend`, `gen_person.py`, `person_palette.png` copied unchanged to `source/fixture_PERSON-001_r002/source/`. `person_hide.glb` reuses its mesh, skin, bind pose, palette, materials and `carry_anchor` byte-identically (`checks/glb_inspect.json` → `fixture_comparison`).
  - POT-001 and HOUSE-001 fixtures (`art/handoffs/bronze-bohemia-opus-v2/fixtures/`), VEG-001 `oak_summer`/`hazel_leafed`/`grass_wet`, ANIMAL-001 `cattle.glb`: copied only into throwaway preview scenes; not part of this return.

## Fixture and input hashes (SHA-256)

Full list: `checks/input_hashes.json`. Key entries:

| Input | SHA-256 |
|---|---|
| PERSON-001 r002 `model.glb` | `f2be7a0f948e554974e2fb76aeda1fa583a8a4f4fe755c8469a0dbf46ae84706` |
| PERSON-001 r002 `source/person_001.blend` (= copy in `source/fixture_PERSON-001_r002/`) | `b2138f9094984ac041984d50f4694a1bc296a3f81847eb5d06f8d5cb492e7963` |
| PERSON-001 r002 `source/gen_person.py` (= copy) | `61b95fd808f6ed48f1beab43299ac00b6d71985a3bb9bf1496cabef5a1d32928` |
| PERSON-001 r002 `source/person_palette.png` (= copy) | `9f2b4fc161398577c6912e2f282bac259df02745cba90f0fd156350c6c4c22fe` |
| POT-001 fixture `model.glb` | `9ea20160b718577e8091c6e91134b32bbd9c6e2379285f50371b756fe35120a0` |
| HOUSE-001 fixture `model.glb` | `14be154b4c679230e9f8c997b8a249d04aad6646846425f4a08a44e795ccc88a` |
| ANIMAL-001 r001 `cattle.glb` | `f4e8ea48ec44c823f0cc7130f4cbea6737814505df61ba0adb3b72feca63f67c` |
| Brief `art/briefs/economy-batch8/HIDE-001.md` | `b881194eab56ffdc5bc482debe2b74ba213fa9c72131d2a699c739044340bee3` |

Research notes (git blobs, branch `docs/economy-research` @ `d8918fdf`): `subsistence.md` `1f65f34ee542d12db7fbc2a8952b459f0ca08f46`, `crafts-exchange.md` `0d53fc56a40a8804d6de53cab6c17d1bdd8327c5`, `README.md` `3b196525045fe6dd1fbe7627379035106d792734`. Batch-4 rules (branch `docs/economy-batch4-briefs` @ `3ea9c4d0`): `44a2942bc8333b4c343bb9d14ec279057f91c19f`.

Historical acceptance and any public release stay with the manager/owner.
