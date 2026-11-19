# VEG-001 r001 — provenance

Status: **provisional_reconstruction** and **draft**, with scale_basis = project_fit. physical_dimensions_m is null. Passing the checks
is not historical approval. Historical acceptance belongs to the manager/owner.

## Brief and inputs

The brief is `jobs/VEG-001.md` and `prompts/VEG-001.md` from release `bronze-bohemia-opus-v2` (batch 2.0). The pack was verified
with `shasum -a 256 -c SHA256SUMS` before work started, and every entry was OK. Fixtures were **copied** into a scratch dir
outside the repo; the pack copies were never modified.

| Input | SHA-256 | Use |
|---|---|---|
| fixtures/PERSON-001/model.glb | a72da131e98c532bf0db6934bd70568fc5d1083d9c3fcd8d11f4083f52cccc12 | 1.70 m scale/readability figure in Blender and Godot previews only (idle pose, frame 0). Not modified, not exported. |
| fixtures/HOUSE-001/model.glb | 14be154b4c679230e9f8c997b8a249d04aad6646846425f4a08a44e795ccc88a | Scale reference in Godot previews only. Not modified, not exported. |
| fixtures/POT-001/model.glb | 9ea20160b718577e8091c6e91134b32bbd9c6e2379285f50371b756fe35120a0 | Read only. Not used in any preview. |
| references/vegetation.svg | bff634ac77f8bb9bd5bd3699170522d630f6dab2365340629322c781509411be | R design envelope: ~5 m oak with 4 states, ~1.6 m hazel, grass clump |
| references/vegetation.png | bc7fa8f0e17baf14266614c9209568055f832d8bbfc77511fb27d9098ddf0db2 | Raster of the same guide (viewed) |
| references/layout.svg | afef643ecdcbd21017d7340af3762186a2164ce3efd4e9027a80eb85d9136b71 | R scene scale |
| references/layout.png | 834f0dbb67347eb77cf5c8910dae847dc9f916a0c37725352671c2053355521d | Raster of the same guide (viewed) |
| references/godot-village.png | 38d93bfda90af71c6431d170e64966701d94bf66a6b0b4928fa1d36caac49bcb | Visual gap: the current trees are "ball on stick" placeholders |
| references/SOURCES.md | 931017005599e68eaeea067e271bfdecf29c2e7500e354bf12f1b2c24dc070c4 | Source limits |
| references/research-notes.md | 1c6ad263082b61ac8568a885e41e66fe03b51aae1a62920bde085d0e3b89c3c5 | Source limits |
| prompts/VEG-001.md | 79c3761ffc992397195d93f8cda291c836032a81eb847ce79653a6a2c8e6c81a | Contract |
| jobs/VEG-001.md | 71040401c6a772a3d2789c6e9073067bd35c558bb84def483fa587b0cf37d48e | Contract |
| templates/kit-asset.json | 2e49186cb1bd1f135da6a6e94867d8e7d223ff37df3acb3f50becfc0c982211c | asset.json template |

The complete list, including README/COMMON/RETURN/CREDITS/fixtures.json, is in `checks/input_hashes.txt`, copied verbatim from
`shasum -a 256` output. The fixture copies used for rendering were re-hashed after use and still matched.

## Evidence classes

| Element | Class | Basis and limits |
|---|---|---|
| Oak presence in the local woody vegetation | **E** | Source A (Šálková et al. 2022, Sci Rep 12:20323; Results pp. 6–7 "Anthracological results", Fig. 5; via references/SOURCES.md and research-notes.md). Oak dominates the charcoal at both sites. This is genus level only. |
| Hazel presence | **E** | Source A, same locator: Březnice has comparatively more hazel. Genus level only. |
| Dry grassland/fallow and wet meadow as reconstructed habitats | **E (bounded)** | Source A, Abstract/Conclusion as summarised in research-notes.md. It does not identify the grass species shown here. |
| Oak-like tree form: short stout trunk, six crooked spreading limbs, ~5 m total height, ≤3.8 m crown | **R** | Game-fit design within the vegetation.svg envelope. It is not a measured tree, and the species is not identified (*Quercus* sp. at most). |
| Seasonal states and colours | **R** | Spring has small light yellow-green tufts with open branches. Summer has a dense green crown. Autumn has a thinning, sagging ochre/russet crown with bare sprays. Winter is bare twig sprays on the shared woody layout. These are design choices, not phenological evidence. |
| Leaf outlines | **R** | Parametric lobed-obovate "oak-like" and serrate-ovate "hazel-like" polygons drawn by `gen_textures.py`. They are not traced from any photo or botanical plate, and no modern botanical images were consulted or incorporated. |
| Hazel-like shrub (7 arching stems, ~1.6 m × ~1.8 m), bare state with no catkins | **R** | Design within the brief's envelope. |
| Grass clumps (dry straw-coloured with seed heads; wet darker, rush-like) | **R** | Generic design proxies, **not** identified ancient grass species. |
| Placement of plants, houses and people in the previews | **F** | Preview-only demonstration layouts (deterministic seed 1100). They are not a settlement plan. |

The source IDs used are A and T1 (Godot 4.5 material and import docs, used for the opaque/cutout material choice). Sources B and C are about
querns and storage, and are not relevant to this job.

## Original and third-party content

- All geometry, textures and scripts are original procedural project work produced in this session, with nothing
  copied from other assets. Textures are drawn from code (`gen_textures.py`). No photographs, scans, paper figures
  or downloaded media were used.
- MR01 (modern barley photo, CC BY-SA 3.0) was **not** used.
- `incorporated_resources` is empty.
- Own-work licence: **unselected**. That is the manager/owner's decision, and no public licence is granted.
- The fixtures (PERSON, HOUSE) appear only in preview renders as private project material. They are not part of any exported GLB.

## Agent and tools

- Agent: GitHub Copilot CLI sub-agent, assigned by the coordinator as Opus 5.5. The model identity is recorded as assigned and
  cannot be independently verified from inside the session.
- Blender 5.2.3 LTS (Khronos glTF Blender I/O v5.2.41), Godot 4.5.1-stable official (f62fdbde1), Python 3.9.6 with
  Pillow 11.3.0 and numpy 1.26.4, on macOS 26.7.1 with an Apple M1 Pro. Godot GPU adapter: "Apple M1 Pro", OpenGL 4.1 Metal-90.5,
  `gl_compatibility`.
