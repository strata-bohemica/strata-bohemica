# KILN-001 r001 — PROVENANCE

All output is **provisional_reconstruction** with `scale_basis = project_fit`. `physical_dimensions_m` is **null**. No historical approval is implied.

## Evidence used (E) and how it was accessed

I did **not** re-read the primary publications for this job. Every E statement below comes from the research proposal `content/research/next-batch/settlement-features.md` (SHA-256 in `checks/input_hashes.json`), which records its own access to the sources. The locators are the ones that document gives.

| ID | Source (as cited in settlement-features.md) | Locator used | What it bounds here |
|---|---|---|---|
| K22 | Kuna et al. 2022, J. Anthropol. Archaeol. 67:101433 (CC BY-NC-ND; cite only) | settlement-features.md §3 KILN-001 bullet 1 → K22 §3.2 | "kilns" = features with a burnt surface or fill |
| Z22 | Chvojka, Kuna et al., Zenodo 10.5281/zenodo.6475797 (CC BY 4.0), `_objekty.xlsx`, `EN_comments.pdf` | settlement-features.md §2 table row KILN-001 and §3 bullet 1 | 11 features coded `O-pec`; excavated area 0.2–1.31 m²; preserved depth 5–25 cm. Comments include "burnt, no finds", "traces of fire", "or storage vessel". A second analyst classes some as natural/undetermined pits, so the **classification is uncertain**. |
| C19 | Chvojka et al. 2019, Archeologické rozhledy 71:267–308 | settlement-features.md §3 KILN-001 bullet 3 | Clay weights as spit supports are **not** confirmed, so **no weights are staged** at the hearth |
| S22 | Šálková et al. 2022, Sci. Rep. 12:20323 | settlement-features.md §2 WOOD-001 row (S22 pp. 6, 10) and §3 "Other candidates" | Charcoal taxa (oak dominant, plus others). Firewood came from the surrounding forests. The species are **not** represented in the textures. |

The **only** dimension bounded by E is the base patch footprint. It is about 1.19 × 1.19 m (about 1.1 m² in plan), a design value chosen inside the excavated range of 0.2–1.31 m². It is not a measurement of any feature.

## Reconstruction (R) — editable design choices

- **Base patch.** The hollow depth (about 0.054 m below the rim crest), the raised fire-reddened rim and the ash, char, red and earth colour zones are R.
- **Superstructure.** It is unknown what stood above the burnt patch (K22/Z22 per the brief), so two **equally provisional** tops are supplied:
  - **Open stone/clay ring:** 9 stones and 3 clay lumps, ring outer radius 0.457 m, top 0.143 m.
  - **Low clay dome:** 0.97 × 0.91 × 0.61 m, wall about 0.10 m, splayed mouth about 0.41 m wide × 0.37 m high on +Z.
  - Neither is verified for Březnice. The dome is not a pottery-kiln or bread-oven claim: no chimney, no brick look.
- **Fires.** The ember and lit states (log arrangement, ember bed, flame form and colour) are R.
- **Placement anchors.** `pot_rest` beside the fire and `tend_origin` front-left of the mouth are R. No cooking technique or posture is implied.
- **Firewood stack.** Form, log length (0.70 m), count and placement are R. The WOOD-001 notes say stack form/size/placement are R.

## Fiction (F)

Placing the kit next to a HOUSE, with a standing person and a pot, is preview staging (F). So are the repeated-instance village layout and the mix of states shown.

## Third-party media

- **MC13** (`content/research/next-batch/references/MC13-firedog-gnm.jpg`): Wolfgang Sauber, "GNM - Feuerbock.jpg", Wikimedia Commons, CC BY-SA 3.0. Revision 1182610648; SHA-256 `7270c020…a333`, which matches `MCregistry.json`. I **viewed it only**. No pixels, shapes or measurements were used, and the fire-dog is **not modelled** (HEARTH-001 is held: regional, ritual-ambiguous comparator).
- No other external images, textures, models or scans were used. `incorporated_resources` is empty.

## Original project work

- `source/gen_kiln.py` and all geometry it generates.
- The 512² atlas `source/textures/kiln_atlas.png`, computed procedurally with numpy (sine/fbm noise and radial gradients).
- All check and preview scripts.

The original-project licence is **unselected**; that is a manager/owner decision.

## Fixtures (read-only, copied into the throwaway Godot project / imported in scratch scenes only)

| Fixture | File | SHA-256 |
|---|---|---|
| PERSON-001 r001 | `art/handoffs/bronze-bohemia-opus-v2/fixtures/PERSON-001/model.glb` | `a72da131e98c532bf0db6934bd70568fc5d1083d9c3fcd8d11f4083f52cccc12` |
| POT-001 r001 | `art/handoffs/bronze-bohemia-opus-v2/fixtures/POT-001/model.glb` | `9ea20160b718577e8091c6e91134b32bbd9c6e2379285f50371b756fe35120a0` |
| HOUSE-001 r001 | `art/handoffs/bronze-bohemia-opus-v2/fixtures/HOUSE-001/model.glb` | `14be154b4c679230e9f8c997b8a249d04aad6646846425f4a08a44e795ccc88a` |

The fixtures appear only in previews and contact checks. None of their geometry is part of any returned GLB. Hashes for all inputs (fixtures, brief, contract, template, registries, MC13) are in `checks/input_hashes.json`.

## Style reference

The accepted v2 returns under `art/returns/bronze-bohemia-opus-v2/` (WORK-001, VEG-001 and others) were consulted for look and preview conventions only: earthy palette, Godot camera, lighting and grid setup. No files from them are included.
