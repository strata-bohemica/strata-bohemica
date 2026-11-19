# THRESH-001 r001 — provenance

Status: draft technical return. Everything here is a **provisional reconstruction** at **project-fit scale**. `physical_dimensions_m` is null, the licence for own work is **unselected** and there is **no historical approval**.

## Evidence classes

| Class | What it covers here |
|---|---|
| **E** (bounded source observation) | Only the general fact that crops were processed on site near the houses and that chaff/straw were abundant by-products (see sources below). No E covers any shape, size, tool, floor, posture or timing in this kit. |
| **R** (inferred / game-fit) | Threshing by beating with a plain wooden stick on a beaten-earth floor; winnowing by tossing in a shallow oval wooden/bark tray; every dimension, outline, colour and litter pattern; the sheaf, straw-bundle and heap forms; the posture, stance, swing and toss timing and loop lengths. The brief states that threshing method, tools, floor and winnowing container are R; no flail, threshing sledge, metal sieve or winnowing basket is attested locally. |
| **F** (fictional) | The villager (PERSON-001 r002) and the placement of the station beside a house in the previews. |

## Sources used

| ID | Locator | Used for | Not used for |
|---|---|---|---|
| SP23 | Šálková T. et al., Research Square preprint rs-2665597/v1, §3.1 p. 7 (hulled-wheat glume bases 51% vs grains 34%) and §3.9.1 p. 10; read via `content/research/economy/subsistence.md` §2.4 (branch docs/economy-research) | E that dehusking/cleaning took place on site, near houses (authors' R reading recorded in the research note) | tool, floor, method or posture |
| C19 | Chvojka O., Menšík P., Šálková T., Kuna M. 2019, *Archeologické rozhledy* 71:267–308, pp. 283, 286, 295; via `subsistence.md` §2.4 and `crafts-exchange.md` (S-CH19 pp. 294–295, 301) | E that cereal processing waste (chaff, glumes, spikelets, straw) was abundant (38% of impressions in clay weights) and reused as temper → supports separate chaff/straw by-product heaps | heap shape/size, any quantity |
| Brief | `art/briefs/economy-batch4/THRESH-001.md`, `README.md` | required models, budgets, anchors, clips; R method choice (stick beating, wooden/bark tray) | — |
| T1 | Godot 4.5 docs: StandardMaterial3D, scene import settings (linked in COMMON.md) | cull mode and loop/optimizer import settings | — |

The sources were read only through the project research notes; the original PDFs were not re-opened in this session. No reference images are cited by the brief. No pixels, meshes or animation from any third-party source were copied.

Heaps have no modelled individual grains (each heap is one smooth mound with a fine texture speckle), so no countable quantity is implied.

## Inputs and fixture hashes (SHA-256)

All read-only; recorded by `source/input_hashes.py` → `checks/input_hashes.json`.

| Input | SHA-256 |
|---|---|
| art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/model.glb | f2be7a0f948e554974e2fb76aeda1fa583a8a4f4fe755c8469a0dbf46ae84706 |
| …/PERSON-001/r002/source/person_001.blend | b2138f9094984ac041984d50f4694a1bc296a3f81847eb5d06f8d5cb492e7963 |
| …/PERSON-001/r002/source/gen_person.py | 61b95fd808f6ed48f1beab43299ac00b6d71985a3bb9bf1496cabef5a1d32928 |
| …/PERSON-001/r002/source/person_palette.png | 9f2b4fc161398577c6912e2f282bac259df02745cba90f0fd156350c6c4c22fe |
| art/handoffs/bronze-bohemia-opus-v2/fixtures/POT-001/model.glb | 9ea20160b718577e8091c6e91134b32bbd9c6e2379285f50371b756fe35120a0 |
| art/handoffs/bronze-bohemia-opus-v2/fixtures/HOUSE-001/model.glb | 14be154b4c679230e9f8c997b8a249d04aad6646846425f4a08a44e795ccc88a |
| art/briefs/economy-batch4/THRESH-001.md | 5242a93718ca72bdb575f142a2e806fb9b0562b19703b605fc29beb27d3132ed |
| art/briefs/economy-batch4/README.md | fe88072c86fc805aa2cdc925cfc6453544d2addea0f8c3003cba8163829f40ec |
| art/handoffs/bronze-bohemia-opus-v2/COMMON.md | 8e22c54cbacf2f03ea29e78f1e88d5c99ebe42d0a8336be34c7bf7c1ae0560b2 |
| art/handoffs/bronze-bohemia-opus-v2/RETURN.md | 5a54eec9cd6be17861abc30d78970b36e35f08c2bafe615d3ed02a40f8165876 |
| art/handoffs/bronze-bohemia-opus-v2/templates/kit-asset.json | 2e49186cb1bd1f135da6a6e94867d8e7d223ff37df3acb3f50becfc0c982211c |

The three files in `source/fixture_PERSON-001_r002/` are byte-identical copies of the r002 source files above (`identical_to_source: true`). They are frozen inputs, not new authored output.

## Original vs incorporated work

- **Original project work (this job):** `gen_props.py` (all nine prop meshes and the procedurally painted 512² atlas `thresh_atlas`), the four clips and two hold nodes made by `gen_threshing.py`, and every check/preview script. The atlas is generated from numpy noise in the script; no photo texture is used.
- **Incorporated project material (unchanged):** PERSON-001 r002 body mesh, UVs, skin weights, 23-joint rig, bind pose, `body`/`garment` materials, `person_palette.png`, `carry_anchor` and the r002 pose solver functions (executed, not edited). `checks/glb_inspect.json` → `fixture_comparison` shows the vertex streams, indices, inverse bind matrices, joint rest TRS, hierarchy, materials and palette are byte-identical to r002 `model.glb`.
- **Preview-only fixtures:** PERSON r002 standing idle (scale), POT-001 and HOUSE-001 in the Godot views; not part of any returned GLB.
- **Third-party media:** none.

Licence: own work is **unselected** (manager/owner decision). Included fixtures are private project material; no public sublicence is granted.
