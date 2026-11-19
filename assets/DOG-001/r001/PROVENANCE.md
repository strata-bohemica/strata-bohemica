# DOG-001 r001 — provenance

## Status

DOG-001 r001 is `models/dog.glb`: one rigged, low-poly, medium-sized generic dog with ten in-place clips. `historical_status = provisional_reconstruction`, `scale_basis = project_fit` and `physical_dimensions_m = null`. The brief (`art/briefs/economy-batch8/DOG-001.md`) is part of the economy batch 8 backlog, a proposal and not a frozen pack. It was executed under the opus-v2 `COMMON.md`/`RETURN.md` contract with the shared batch rules of `art/briefs/economy-batch4/README.md`. Technical completion is not historical approval.

## Author and licence of this work

- **Author:** GitHub Copilot autonomous modelling agent (dispatched as the "Opus 5.5" slot) for the Bronze Bohemia project. `source/gen_dog.py` generated every vertex, bone, weight, keyframe and atlas pixel. No external mesh, scan, photograph, motion capture or texture was used or adapted.
- **Licence:** unselected original project work. The manager/owner decides; this revision grants no public licence.
- **Tools:** Blender 5.2.3 LTS (glTF I/O 5.2.41), Godot 4.5.1.stable.official.f62fdbde1 (Compatibility renderer, OpenGL 4.1 Metal-90.5, Apple M1 Pro), Python 3 with numpy and Pillow, ffmpeg, macOS.
- **Project code reused:** the pose/IK/contact machinery, the independent GLB inspector, the Blender re-import check, the A/B Godot import probe and the GPU capture pattern were adapted from the accepted ANIMAL-001 r001 return (`art/returns/bronze-bohemia-v3/ANIMAL-001/r001/source/`, same project, same author pipeline). Changes: dog proportions and mesh, a fourth (paw) bone per leg, dict-based leg specs, new clips and design solves, 60 fps keys, `animation/fps=60` import setting, dog-specific demos. Both files are recorded in `checks/input_hashes.json`.

## Incorporated resources

None. `source/textures/dog_atlas.png` (256×256) is written by the generator from the colour tables `COAT`/`CELLS` and a deterministic value-noise function; it contains no photo-derived pixels. The GLB embeds the same bytes (SHA-256 `e4e1d868…945c`).

## Sources and how they were used

| ID | Source | Used for | Class |
|---|---|---|---|
| Brief | `art/briefs/economy-batch8/DOG-001.md` | Medium-sized generic dog; ANIMAL-001 rig conventions; ≤ 24 bones, in-place clips, ≤ 1000 triangles, 1 material; the eight clip names with walk 1.2 m/s and trot 2.5 m/s; herding demo at ortho 16/25 with GPU GIF/MP4 | R/design |
| KY16 | Kyselý R. 2016, *Živa* 2016/5:225–229 — cited by the brief ("dogs are regional domestic animals … cite only") | Species presence only (a regional domestic animal). **Not opened in this session**; the economy research notes mark KY16 "cite only; reprint forbidden". Nothing was copied. | E (regional, as cited; unverified here) |
| S22 via research notes | Šálková et al. 2022, *Sci. Rep.* 12:20323, p. 12, as summarised in `content/research/economy/subsistence.md` (branch `docs/economy-research`) | Negative evidence: no animal bones survive at Březnice, so any dog there is a regional reconstruction | E (negative) |
| subsistence.md §2.8, F8 | `content/research/economy/subsistence.md` (branch `docs/economy-research`), herding section | Context: communally herded cattle/sheep, herder rota (R). F8 risk note: "don't present goats, horses, chickens or dogs as evidenced locally". The dog is therefore labelled R throughout. | R / guard rail |
| crafts-exchange.md | Same branch | Read for completeness; no dog content (it lists KY16 as not inspected) | — |

**No reference image was used.** None of the research registries lists a dog image. Shape, colours and motion are generic forms, not a breed.

## Evidence classification (E / R / F)

- **E (negative):** no faunal remains at Březnice. Nothing in the model is site evidence.
- **E (regional, cite only, as given by the brief):** dogs as domestic animals in the region. Not verified in this session.
- **R (all modelled content):**
  - size (withers ~0.52 m, ear tips 0.71 m, nose to tail tip 1.11 m) and proportions;
  - semi-erect ears, hanging tail, four restrained coat colours (tawny, grey agouti, dark with tan underside, pale cream);
  - gaits: lateral-sequence walk at 1.2 m/s, diagonal trot at 2.5 m/s (speeds set by the brief), stride lengths and duty factors;
  - sit, lie (sternal, "sphinx"), lie-down and rise sequences, sniffing posture;
  - the role of the dog as a herding companion.
- **F:** demo placement only — a herder, a small flock, the house and pot in the previews.

## Fixtures and reference returns (read-only; copied into throwaway projects/scenes only)

SHA-256 values from `checks/input_hashes.json`:

| Input | SHA-256 |
|---|---|
| PERSON-001 r002 `model.glb` (1.70 m; used instead of MILK-001 `person_herding`, which is not merged) | `f2be7a0f948e554974e2fb76aeda1fa583a8a4f4fe755c8469a0dbf46ae84706` |
| ANIMAL-001 r001 `models/sheep.glb` | `beefdac8b2a2f427f62e6254ff4a56ffa0f07893a460fc240b136d52a96611b0` |
| POT-001 fixture `model.glb` | `9ea20160b718577e8091c6e91134b32bbd9c6e2379285f50371b756fe35120a0` |
| HOUSE-001 fixture `model.glb` | `14be154b4c679230e9f8c997b8a249d04aad6646846425f4a08a44e795ccc88a` |

`asset.json` `fixture_hashes` lists the full SHA-256 of every GLB read. No fixture file is included in this return or modified.
