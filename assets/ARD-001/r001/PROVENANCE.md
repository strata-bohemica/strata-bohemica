# ARD-001 r001 — provenance

## Evidence classes

The whole job is **R** (regional/general reconstruction). No ard, yoke, furrow, tillage trace or cattle traction is attested at Březnice. Following the brief, nothing here is a local claim.

| Statement | Class | Source / locator |
|---|---|---|
| Animal traction in the Czech area is reliably evidenced from the end of the Eneolithic. Real ploughs are found directly from the start of the Bronze Age. Wooden yokes are known in Europe from the second half of the 4th millennium BCE. Cattle gave "milk and draught power". | E (regional synthesis, read via the project's research file) | KY16 p. 227, quoted in `content/research/economy/subsistence.md` §2.3 (branch `docs/economy-research`, file SHA-256 `abc5b0d6…5232c6d`). KY16 is cite-only (reprint forbidden); its figures were not used. |
| "An ard pulled by a cattle pair is a defensible regional reconstruction for Březnice, but it has no local evidence." | R (research file's own judgement) | same section |
| Czech one-season experiment: a hoe converted permanent grassland; "a scratch plough or wooden spade worked only on existing arable land without dense sward". | E (experiment, not Bronze Age observation) | H15 p. 31 abstract, pp. 32–33 methods, via `subsistence.md` §2.3 |
| Replica-tool experiment suggested ploughing of previously deforested pasture. | E (as cited by S22) | S22 p. 3 (citing Pavelka et al.), via `subsistence.md` §2.3 |
| The tillage row in the activity table puts tillage in spring (and in autumn for winter crops), with hoe/spade or ard + cattle pair. | R | `subsistence.md` activity table (line "Tillage") |
| `crafts-exchange.md` was read. It has no tillage, ard or yoke content relevant to this job. | — | — |
| Ard type (crook ard with a separate beam, T-handle), the 2.06 m length, the 7 cm share depth, wedge, rawhide lashings, the beam-end peg and the rope sling | R | design choice, sized to the project's PERSON and cattle |
| Neck (withers) yoke with pins and throat thongs, 1.0 m between neck centres, seat in front of the withers | R | design choice. Horn yokes are equally possible regionally. Chosen to fit the ANIMAL-001 rig. |
| Ploughman: posture, two-handed overhand grip, 0.48 m steps, 0.6 m/s | R | design choice |
| Furrow strip: 0.25 m furrow spacing, ridge height, soil colours | R | design choice; colours matched to FIELD-001's bare soil |
| People, placement, plot layout in the demos | F | preview only |

No physical dimension is supported by a measured source, so `physical_dimensions_m` is null. No figure, photo or drawing was copied. No reference images were cited for this job.

## Original and third-party inputs

- **Original project work (this job):** every script in `source/`, the three kit GLBs, the procedural atlas `source/textures/ard_kit_atlas.png`, the three new clips, the `stilt_hold` node and every preview/check. The licence is **unselected** and is the manager/owner's decision.
- **Incorporated project material, unchanged:** the PERSON-001 r002 mesh, skin, bind pose, materials, palette and `carry_anchor`, inside `models/person_ploughing.glb`. Byte parity is in `checks/glb_inspect.json` → `parity_with_PERSON_r002`. The r002 `gen_person.py` pose solver is executed unchanged (without its `main()`). Copies are in `source/fixture_PERSON-001_r002/` and are byte-identical (`checks/input_hashes.json` → `copies_identical_to_r002: true`).
- **Read-only references, not incorporated:** ANIMAL-001 r001 `cattle.glb` (neck measurement, contact checks, demos), FIELD-001 r001 `barley_bare.glb`, the HOUSE-001/POT-001 r001 fixtures, and PERSON-001 r002 `model.glb` (standing scale figure). They are copied only into the throwaway Godot project in the scratch folder.
- **Third-party media:** none. Tools only: Blender 5.2.3 with its bundled glTF I/O, Godot 4.5.1, ffmpeg, Python, NumPy and Pillow.

## Input hashes (SHA-256, `checks/input_hashes.json`)

| Input | Path | SHA-256 |
|---|---|---|
| PERSON-001 r002 model.glb | `art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/model.glb` | `f2be7a0f948e554974e2fb76aeda1fa583a8a4f4fe755c8469a0dbf46ae84706` |
| PERSON-001 r002 source/person_001.blend | `art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/source/person_001.blend` | `b2138f9094984ac041984d50f4694a1bc296a3f81847eb5d06f8d5cb492e7963` |
| PERSON-001 r002 source/gen_person.py | `art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/source/gen_person.py` | `61b95fd808f6ed48f1beab43299ac00b6d71985a3bb9bf1496cabef5a1d32928` |
| PERSON-001 r002 source/person_palette.png | `art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/source/person_palette.png` | `9f2b4fc161398577c6912e2f282bac259df02745cba90f0fd156350c6c4c22fe` |
| ANIMAL-001 r001 models/cattle.glb | `art/returns/bronze-bohemia-v3/ANIMAL-001/r001/models/cattle.glb` | `f4e8ea48ec44c823f0cc7130f4cbea6737814505df61ba0adb3b72feca63f67c` |
| FIELD-001 r001 models/barley_bare.glb | `art/returns/bronze-bohemia-opus-v2/FIELD-001/r001/models/barley_bare.glb` | `aa3d50b75543ed92eab05405189f5754cee3259ae4b17d254b4cab8b8833deec` |
| HOUSE-001 fixture model.glb | `art/handoffs/bronze-bohemia-opus-v2/fixtures/HOUSE-001/model.glb` | `14be154b4c679230e9f8c997b8a249d04aad6646846425f4a08a44e795ccc88a` |
| POT-001 fixture model.glb | `art/handoffs/bronze-bohemia-opus-v2/fixtures/POT-001/model.glb` | `9ea20160b718577e8091c6e91134b32bbd9c6e2379285f50371b756fe35120a0` |
| COMMON.md | `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` | `8e22c54cbacf2f03ea29e78f1e88d5c99ebe42d0a8336be34c7bf7c1ae0560b2` |
| RETURN.md | `art/handoffs/bronze-bohemia-opus-v2/RETURN.md` | `5a54eec9cd6be17861abc30d78970b36e35f08c2bafe615d3ed02a40f8165876` |
| templates/kit-asset.json | `art/handoffs/bronze-bohemia-opus-v2/templates/kit-asset.json` | `2e49186cb1bd1f135da6a6e94867d8e7d223ff37df3acb3f50becfc0c982211c` |
| brief ARD-001.md | `art/briefs/economy-batch6/ARD-001.md` | `38078c530fa2bfffdc57ec53fcef23132f2868d5726f5c6b7092764deee3f907` |
| brief batch 6 README.md | `art/briefs/economy-batch6/README.md` | `c8dc1d65e6b6989548e3e96a57f6cfa57698a3dda153e1ebdea80ecdced5a0eb` |
| shared rules, batch 4 README.md (PR #30, not in this checkout) | `art/briefs/economy-batch4/README.md` (read from a sibling clone) | `fe88072c86fc805aa2cdc925cfc6453544d2addea0f8c3003cba8163829f40ec` |
| research `subsistence.md` (branch docs/economy-research) | `content/research/economy/subsistence.md` | `abc5b0d656dc8cdd62717e94d383f9d585fdcc3fec2ba9c0483a8b2b95232c6d` |

## Authorship

GitHub Copilot autonomous modelling agent, dispatched as the "Opus 5.5" modeller slot. The underlying model identity cannot be verified from inside the session. Historical acceptance and any public release stay with the manager/owner.
