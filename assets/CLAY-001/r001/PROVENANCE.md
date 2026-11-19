# CLAY-001 r001 — provenance

Status: draft, `provisional_reconstruction`, `scale_basis = project_fit`, `physical_dimensions_m = null`. The original-project licence is **unselected**; that is the manager/owner's decision. This return makes no historical approval claim.

## Evidence classes

| Item | Class | Source and exact locator | What it supports and what it does not |
|---|---|---|---|
| A clay pit existed on site | **E** | `content/research/economy/crafts-exchange.md` §2.2 (branch `docs/economy-research`): feature `O-hliník` 2005-O-05, ~12 m², 0.3 m deep (S-ZEN, Zenodo 10.5281/zenodo.6475797, tables `_objekty`, `_keramika_mazanice_zavazi_v2`); Kuna et al. 2022 (S-KU22) p. 4 | It supports having a clay pit asset and a shallow depth class (≤0.4 m). It does **not** give the plan shape, profile, tool marks or spoil handling. Those are R. The asset footprint (≤3.0 × 2.5 m brief limit) is smaller than the ~12 m² excavated feature and represents a working scoop. |
| Daub with up to three plaster layers and a white coating | **E** | `crafts-exchange.md` §2.4; S-KU22 p. 10 | It supports a white-coated patch variant next to the wet-brown re-daub. Patch size, outline, thickness, colour and position on the wall are R. The white material (lime, clay slip, …) is not established. |
| Crop-processing waste used as temper | **E** for clay weights (S-CH19). S22 p. 8 names "ceramics or daub" as example uses. | `crafts-exchange.md` §2.3; Chvojka et al. (S-CH19) pp. 294–295, 301; `subsistence.md` l. 107 (S22 p. 8) | Chaff as an ingredient of daub is plausible. Its amount, its look in the mix and the treading method are **R**. |
| Dig → carry → heap → mix with chaff + water → re-daub / re-plaster loop | **R** | `crafts-exchange.md` §4 F1, F5; brief CLAY-001 | This is a game-loop description, not an observed sequence. |
| Pit shape, digging stick (1.10 m, fire-darkened tip), two-handed thrust/lever technique, treading as the mixing method, palm smearing, heap shapes and colours, puddle | **R** | Brief marks these R | Game-fit illustration only. |
| Preview yard layout, people, which house is repaired | **F** | — | Fictional placement. |

Two more research notes were read and used:

- `content/research/next-batch/settlement-features.md` has a CLAYPIT-001 row in its candidate table (line 39) and a note at line 98. Both repeat the same E items with K22 §3.2 and §5.3.1 and Z22: clay pit 5/05, ~12 m² excavated, 30 cm preserved; daub with at most three plaster layers and a white coat. They also mark the shape as a "shallow irregular scoop (**R**)" and the tools and mixing method as R.
- `subsistence.md` lines 107 and 117–120 (S22 p. 8; C19 p. 295) report chaff and straw reused as temper "in ceramics or daub". That is the basis for the R chaff in the mix patch.

## Original and incorporated inputs

- **Original project work (this job):** all prop geometry, the procedural 512² atlas (`source/textures/clay_atlas.png`, seeded numpy noise, no photographs or third-party pixels), the clip keyframes, the `tool_hold` node, and all scripts except the two adapted ones listed below.
- **Project fixtures (unchanged, private project material, no public sublicence):**
  - PERSON-001 r002: body mesh, rig, skin, palette and `carry_anchor`. These are copied byte-identical into `person_clay.glb`; the vertex streams, indices, inverse bind matrices, joint rest TRS, materials and palette are proven equal in `checks/glb_inspect.json` → `fixture_comparison`. Its `gen_person.py` pose solver is executed unchanged from `source/fixture_PERSON-001-r002/`.
  - HOUSE-001 r001: used read-only for wall-patch fitting, contact checks and previews. It is not redistributed in `models/`.
- **Adapted project code:** `source/inspect_glb.py` is adapted from WORK-001 r001 `source/inspect_glb.py`; only the person file name, the clip-seam list and the fixture-idle comparison changed. `source/godot/set_import.py` follows the WORK-001 r001 helper of the same name. Both are internal project code.
- **Third-party media:** none.

## Fixture and input hashes (SHA-256)

These are recorded by `source/input_hashes.py` in `checks/input_hashes.json`:

| Input | SHA-256 |
|---|---|
| `art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/model.glb` | `f2be7a0f948e554974e2fb76aeda1fa583a8a4f4fe755c8469a0dbf46ae84706` |
| `art/handoffs/bronze-bohemia-opus-v2/fixtures/HOUSE-001/model.glb` | `14be154b4c679230e9f8c997b8a249d04aad6646846425f4a08a44e795ccc88a` |
| PERSON r002 `source/person_001.blend`, `gen_person.py`, `person_palette.png` | see `checks/input_hashes.json` (copies in `source/fixture_PERSON-001-r002/` are byte-identical: `true` ×3) |

## Agent

The job was dispatched as the "Opus 5.5" modeller slot, a GitHub Copilot agent session. A previous session started the job and was stopped by a runtime restart. This session verified its GLBs by re-generation (byte-identical), then changed the `plaster` and `dig` timing (see CHANGELOG) and the clay colours, and completed checks, previews and documents. The underlying model identity cannot be verified from inside the session.
