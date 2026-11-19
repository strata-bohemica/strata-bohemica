# PARCH-001 r001 — provenance

## Status

PARCH-001 r001 is an **R study** of grain parching and an optional job. No Březnice source inspected for the economy research reports parching or kiln-drying (`subsistence.md` §2.4, "R only"). `historical_status = provisional_reconstruction`, `scale_basis = project_fit`, `physical_dimensions_m = null`. Technical checks are in CHECKS.md. Historical acceptance and any public release are decisions for the manager and owner.

## Author, tools and licence

- **Author.** A GitHub Copilot autonomous modelling agent, dispatched as the "Opus 5.5" modeller slot. The underlying model identity cannot be verified independently from inside the session. The agent wrote every script in `source/` except the copied PERSON fixture files (below).
- **Tools.** Blender 5.2.3 LTS with glTF I/O 5.2.41; Godot 4.5.1.stable.official.f62fdbde1 (Compatibility renderer, OpenGL 4.1 Metal-90.5, Apple M1 Pro); Python 3.9.6 with numpy 1.26.4 and Pillow 11.3.0; ffmpeg; git (read-only). macOS.
- **Licence.** Not selected. Original private project work; the licence is the manager's or owner's decision. No public licence is granted.

## Inputs

### Original work in this revision

Generated procedurally by `source/gen_props.py` and `source/gen_parching.py`:

- the parching tray (sherd / clay plate), its grain layer and the stir stick meshes, their anchors;
- the 128² atlas `source/textures/parch_atlas.png` (flat colours plus hashed speckle; no photographic pixels), embedded in the three prop GLBs;
- the `stick_hold`, `hearth_place`, `tray_place` and `stick_rest` nodes;
- the clips `parch_enter`, `parch_stir` and `parch_exit`.

No photograph, scan, motion capture, reference image or third-party mesh was used, traced or adapted.

### Copied internal project fixture (PERSON-001 r002)

`models/person_parching.glb` reuses the accepted PERSON-001 r002 body, rig, skin weights, UVs, materials, palette image and `carry_anchor` without change. `checks/glb_inspect.json` (`fixture_comparison`) finds every vertex stream and index buffer, the inverse bind matrices, joint names/order/parents/rest TRS, the palette PNG, the materials (single-sided) and `carry_anchor` identical to `art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/model.glb`. The five r002 clips are not included; three new clips and four nodes were added. The clips are posed with the unchanged r002 solver executed from the byte-identical copy `source/fixture_PERSON-001_r002/source/gen_person.py`; `gen_parching.py` works on a copy of `person_001.blend` (the shared fixture was only read).

### Other read-only inputs (SHA-256, recomputed in `checks/input_hashes.json`)

| Input | SHA-256 | Use |
|---|---|---|
| `art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/model.glb` | `f2be7a0f948e554974e2fb76aeda1fa583a8a4f4fe755c8469a0dbf46ae84706` | Byte comparison; standing 1.70 m figure in previews |
| `…/PERSON-001/r002/source/person_001.blend` | `b2138f9094984ac041984d50f4694a1bc296a3f81847eb5d06f8d5cb492e7963` | Copied unchanged to `source/fixture_PERSON-001_r002/source/` |
| `…/PERSON-001/r002/source/gen_person.py` | `61b95fd808f6ed48f1beab43299ac00b6d71985a3bb9bf1496cabef5a1d32928` | Copied unchanged; pose solver reused |
| `…/PERSON-001/r002/source/person_palette.png` | `9f2b4fc161398577c6912e2f282bac259df02745cba90f0fd156350c6c4c22fe` | Copied unchanged |
| `art/returns/bronze-bohemia-v3/KILN-001/r001/models/hearth_base.glb` | `2e12bf68e61480642433a85b1d4c949f23b7207032adbb00fcef2cbcef631de2` | Host (read-only): placed on `hearth_place` in checks/previews |
| `…/KILN-001/r001/models/hearth_open_top.glb` | `c13b6fe99d3921707dc4856dbad489f5118e84c7ace8690d7911324455467420` | Host stone ring (brief: "reuse KILN-001 hearth_open_top") |
| `…/KILN-001/r001/models/fire_embers.glb` | `c9dfda43f5390b5fb305fcf36ad167fa0cf2062000eeb3b21267fdb37b9a5a82` | Ember bed the tray rests on |
| `…/KILN-001/r001/models/firewood_stack.glb` | `125cc0121e0cf5214de30af9ee2fb79da3260258db553605e1a4aec3b58c09f5` | Preview dressing at KILN `firewood_spot` |
| `art/handoffs/bronze-bohemia-opus-v2/fixtures/POT-001/model.glb` | `9ea20160b718577e8091c6e91134b32bbd9c6e2379285f50371b756fe35120a0` | Scale context in village previews only |
| `art/handoffs/bronze-bohemia-opus-v2/fixtures/HOUSE-001/model.glb` | `14be154b4c679230e9f8c997b8a249d04aad6646846425f4a08a44e795ccc88a` | Scale context only |
| `art/returns/bronze-bohemia-opus-v2/VEG-001/r001/models/{oak_summer,hazel_leafed,grass_wet}.glb` | see `checks/input_hashes.json` | Village context only |

KILN-001 `asset.json` and `CHECKS.md` were read for its anchors, ring radii and heights (hashes in `checks/input_hashes.json`). The sibling job COOK-002 r001 (economy batch 8, in progress in another clone) was read for its crouch/keying/Godot capture code structure; nothing from it is shipped as a model and all values here were set and measured for this job.

## Sources and evidence classes

| Source (branch `docs/economy-research`, blob in `checks/input_hashes.json`) | Locator | What it supports |
|---|---|---|
| `content/research/economy/subsistence.md` | §2.4 "Crop processing: threshing, winnowing, dehusking, parching", last bullet: "**Parching:** no Březnice source inspected here reports parching or kiln-drying. **R only.**" | The whole job is labelled R and optional |
| `content/research/next-batch/README.md` | paragraph on `O-pec` records ("burnt surface/fill and uncertain classifications, not eleven demonstrated standing ovens") | No grain-drying function is attached to any oven/burnt feature; parching is shown on the ordinary open hearth |
| `content/research/economy/crafts-exchange.md` | read for context | No statement used |

| Element | Class | Note |
|---|---|---|
| Grain parching as an activity in the village | R | Not attested locally; optional illustration |
| Re-used large flat base sherd / clay plate as the parching surface, ~0.5 m | R | Brief's suggestion; size, low rim, break, soot, convex underside are design choices |
| Parching on embers (KILN-001 open top + `fire_embers`), tray inside the stone ring on the ember logs | R | Host geometry is KILN-001 (itself R) |
| Thin grain layer (~12 mm), colour/texture | R | No cereal species implied |
| Peeled stir stick with charred end, 0.66 m | R | |
| Crouched posture, overhand right-hand grip, oval stirring, picking the stick up from the floor | R | Game-fit motion; no posture evidence |
| Who parches, when, how much | F | Driven by the game's simulation |

## Fixtures not modified

Shared fixtures and accepted returns were only read and copied into throwaway Godot projects or Blender scenes. No file outside `art/returns/economy-batch9/PARCH-001/r001/`, the sibling ZIP and the scratch directory was written.
