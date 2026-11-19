# POT-001 r001 — provenance

Brief: `jobs/POT-001.md` / `prompts/POT-001.md`, spec 1.0, Bronze Bohemia handoff v1. Status: **draft**, `scale_basis=project_fit`, `historical_status=provisional_reconstruction`.

## Authorship and licence of this return

- Model, generator scripts (`source/*.py`, `source/build.sh`), the `.blend`, the procedural texture `pot_basecolor_512.png` and every preview PNG were made on 2026-11-06 by GitHub Copilot (AI modelling agent) for the Bronze Bohemia project.
- Every vertex comes from the editable lathe profile in `source/gen_pot.py`. No external mesh, scan, photo pixel, crop or traced outline was incorporated.
- The texture is pure procedural noise from NumPy with fixed seed 1100. It is not derived from a photograph.
- The project manager assigns the licence for this own work. No third-party licence terms bind this asset because no third-party material was incorporated.
- Preview-only objects are the ground, 1 m grid, axis bars, 1.7 m grey proxy, yellow grip bars and labels. They exist only in `render_previews.py` and are not in `model.glb` or the `.blend`.

## References consulted

| ID | Source | Creator / licence | How it was used |
|---|---|---|---|
| WM01 | [Pottery and tools, 1250-950 BC, Museum of Western Bohemia, 187823.jpg](https://commons.wikimedia.org/wiki/File:Pottery_and_tools,_1250-950_BC,_Museum_of_Western_Bohemia,_187823.jpg) (pack copy `references/WM01-pottery-tools.jpg`, 1280×853 thumbnail, SHA256 `aad56408…5acba`) | Zde, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) | I looked at the photo for broad ceramic appearance only: matte, mid-to-dark earth-brown fired clay with uneven darker patches. I took no profile, proportion, handle or dimension from it, and no pixels were copied. |
| WM02 | Knovíz cremation urn | Zde, CC BY-SA 4.0 | **Not used.** The brief says it is a funerary urn and not this pot's profile or use reference. |
| WM03 | Sickle/fibula | Zde, CC BY-SA 4.0 | Not relevant to this job; not used. |
| — | Current game placeholder `scripts/household_kit.gd` (`_vessel()` profile, `CARRY_OFFSET (-0.5, 0.85, 0)`, clay colour `#a37a5b`) | Project code | Supplied the 0.46 m design envelope named in the brief. I used it as a comparison for proportions and the proxy grip test. No code or mesh was copied. |

The archaeological identities and dates in WM01 come from the Commons uploader's description and have no independent museum verification (see `references/SOURCES.md`, `MANAGER-CHECK.md`). This return makes no claim based on them.

## E / R / F classification

- **E (evidence):** none. No inspected source gives this pot's profile, size, wall thickness, capacity, colour, handles or use.
- **R (reconstruction):** all geometry and appearance:
  - the rounded belly, narrower neck and outturned simple lip
  - 0.46 m maximum diameter and height (the game envelope)
  - the ~11 mm wall, 24 mm base and flat base
  - no handles or decoration
  - 1 % ovality and up to 4 mm rim dip
  - earth-brown mottled colour with a slightly darker interior
  - roughness 0.9
  - `carry_grip` at mid-height (0.23 m)
- **F (fiction):** its role as a village water-carrying pot, and any placement or story use. The cavity to the rim is about 45 L, but that is a geometric consequence of the design envelope, not a capacity claim. The simulation's cargo 3 is an abstract count.

## Measured vs inferred

- **Measured from the exported GLB:**
  - bounds 0.460 × 0.460 × 0.4509 m (W×H×D)
  - 924 triangles, 1 material, one 512×512 texture
  - anchors as listed
  - these are export facts about the model, not archaeological measurements
- **Inferred or designed:** everything about the ancient object. `physical_dimensions_m` stays null.
- **From captions:** nothing was relied on.

## Adaptations

None of the reference media were adapted. If a later revision adds photo-derived texture or profile data, record it separately with Zde/CC BY-SA 4.0 attribution.
