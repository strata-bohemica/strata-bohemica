# WORK-001 r001 — provenance

## Status

WORK-001 r001 is a provisional reconstruction and food-processing study, not an excavated reconstruction. `historical_status = provisional_reconstruction`, `scale_basis = project_fit` and `physical_dimensions_m = null`. Technical checks are reported in CHECKS.md. Historical acceptance and any public release are decisions for the manager and owner.

## Author, tools and licence

- **Author.** A GitHub Copilot autonomous modelling agent, dispatched as the "Opus 5.5" modeller slot for the Bronze Bohemia project. The underlying model identity cannot be verified independently from inside the session. The agent wrote every generator in `source/`.
- **Tools.** Blender 5.2.3 LTS with glTF I/O 5.2.41, Godot 4.5.1 stable (Compatibility renderer, OpenGL 4.1 Metal-90.5, Apple M1 Pro), Python 3.9.6 with numpy 1.26.4 and Pillow 11.3.0, and ffmpeg 9.0.2. The host was macOS 26.7.1.
- **Licence.** Not selected. This is original private project work, and the licence is the manager's or owner's decision. No public licence is granted.

## Inputs

### Original work in this revision

These were generated procedurally by `source/gen_props.py` and `source/gen_grinding.py`:

- quern, handstone and grain_patch meshes;
- the 256² atlas `source/textures/work_props_atlas.png`, also embedded in the three prop GLBs;
- the quern and handstone anchors;
- the `handstone_hold` node;
- the clips `grind_enter`, `grind` and `grind_exit`.

No photograph, scan, motion capture or third-party mesh was used, traced or adapted. The atlas is procedural noise over flat colours and contains no photo-derived pixels.

### Copied internal project fixture

PERSON-001 r001 is private project material with an unselected licence. It is not accepted historical evidence.

`models/person_grinding.glb` reuses the r001 body, rig, skin weights, UVs, palette image and `carry_anchor` without change. The independent comparison in `checks/glb_inspect.json` (`fixture_comparison`) found these byte-identical to `fixtures/PERSON-001/model.glb`:

- every vertex stream and index buffer;
- the inverse bind matrices;
- the joint rest TRS, names, order and hierarchy;
- the palette PNG.

The only material difference is `doubleSided`: the fixture has `true` and this copy omits the key, which means `false`. This is the local material deviation the brief asked for. It does not imply that PERSON r001 was accepted. The five r001 clips are not included, and three new clips plus the `handstone_hold` node were added. The new clips are posed with the unchanged r001 solver (`gen_person.py`), executed from the byte-identical copy in `source/fixture_PERSON-001/`.

### Fixture hashes (SHA-256)

These are recomputed in `checks/input_hashes.json`. They match `references/fixtures.json`.

| Fixture | SHA-256 | Use |
|---|---|---|
| `fixtures/PERSON-001/model.glb` | `a72da131e98c532bf0db6934bd70568fc5d1083d9c3fcd8d11f4083f52cccc12` | Interface reference and byte comparison; standing 1.70 m scale figure in previews |
| `fixtures/PERSON-001/source/person_001.blend` | `f48900bae80afe629cbda7043959fbd052073be195d954a6f6356f0ccb9792a6` | Copied unchanged to `source/fixture_PERSON-001/source/`; opened by `gen_grinding.py` |
| `fixtures/PERSON-001/source/gen_person.py` | `7f3348ef9dead10de541277e7c29ca1f4dbf7d860349ca20d0389d67ff781534` | Copied unchanged; the pose solver is reused |
| `fixtures/PERSON-001/textures/person_palette.png` | `9f2b4fc161398577c6912e2f282bac259df02745cba90f0fd156350c6c4c22fe` | Copied unchanged; the blend's external texture |
| `fixtures/POT-001/model.glb` | `9ea20160b718577e8091c6e91134b32bbd9c6e2379285f50371b756fe35120a0` | Scale context in previews only; no stored-grain claim |
| `fixtures/HOUSE-001/model.glb` | `14be154b4c679230e9f8c997b8a249d04aad6646846425f4a08a44e795ccc88a` | Scale context in previews only |

The shared fixtures were only read and copied. `shasum -c SHA256SUMS` in the pack passed before work started.

### Manager guides

`references/work.svg`/`work.png`, `layout.png` and the `godot-*.png` captures were viewed as design guidance (R). They are not archaeology and no pixels from them were copied.

## Sources and evidence classes

The agent did not open B or C again in this session. The source statements below come from the pack's `references/SOURCES.md` and `references/research-notes.md`.

| ID | Locator | Used for | Not established |
|---|---|---|---|
| B | Šálková et al. 2025, *Archaeological Prospection* 32:525–548, §§2.2–2.3, §3.4, §4.1, Table 1 (Feature 2/09 grinding slab) | The grinding-slab context, with grass, wheat and legume starch on the slab | Dimensions, stone type, handstone shape, posture, work-area layout, contents of the stores |
| C | University of South Bohemia LAPE, "Phytolith and Starch Grain Analysis", subsection "Buried Houses and Grinding Tools from the Late Bronze Age in Březnice near Bechyně" | Identifies the implement as a saddle quern used for multifunctional plant and animal-product processing | Dimensions and posture |
| T1 | Godot 4.5 standard material (Transparency) and advanced scene import documentation | Cull and import settings, tested on the actual 4.5.1 output | — |
| A | Šálková et al. 2022 | Not used. `grain_patch` makes no barley or cultivar claim. | — |

### E — bounded evidence used

- A saddle quern or grinding slab existed in the Březnice context and was used for plant processing, including cereals and legumes, with broader plant and animal-product use (B §3.4; C). This alone justifies a lower stone, an upper handstone and a grinding action.

### R — reconstruction and design choices

All of these are editable.

- **Quern.** About 0.547 × 0.323 × 0.121 m, a rounded irregular slab with a slightly narrower far end. The working surface is a restrained lengthwise concave arc (radius 2.4 m, 12 mm rise to the ends), flat across. The stone is a granite-like grey with a lighter worn top. The size is game-fit from the brief.
- **Handstone.** 0.22 × 0.10 × 0.07 m, loaf-shaped. It is held crosswise with both palms on top and the fingers curled over the far edge. Its base follows the same arc so that the stone-on-stone contact is even.
- **Grain patch.** Three low heaps of generic meal plus three flecks on the floor in front of the quern. They stand in for the product being pushed off the far end. Nothing about the crop is implied.
- **Posture and technique.**
  - Kneeling on both knees, toes tucked, trunk leaning about 76° forward at the back of the stroke.
  - Two push-pull strokes per 2 s, with 0.22 m of handstone travel.
  - The pelvis rocks 0.055 m forward with each push.
  - Entry and exit: step back with the right foot, then the left, onto the balls of the feet in a half crouch; lower both knees together; lean forward and reach. Exit is the reverse.
  - A quern finding does not establish any of this.
- **Placement.** The worker origin is 0.55 m behind the quern centre, from the brief. The handstone rests at the back of the stroke when not in use.

### F — fiction

- Who grinds, when and where in the village. These come from the manager's fictional population and layout.
- The context scene in the previews: house, pot and standing person spacing.

## Measured and inferred values

- **Measured on the exported GLBs and in Godot 4.5.1:**
  - triangles, materials, textures, bounds, anchors, clip durations and keys;
  - seams, contact clearances and loop behaviour;
  - culling flags.
  - See CHECKS.md and `checks/`.
- **Inferred or invented:** every physical dimension, posture and timing. `physical_dimensions_m` stays null.
