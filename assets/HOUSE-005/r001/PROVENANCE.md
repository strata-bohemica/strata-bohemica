# HOUSE-005 r001 (type B) — provenance

> **Provisional reconstruction, not a plan of a Březnice house.** No complete house plan is verified at Březnice, and no unambiguously proven residential post house is known in South Bohemia (Chvojka 2009, 130, via the brief). Type B follows the **Liptice farmstead dwelling** (about 5 × 8.5 m, three rows of posts; a Knovíz farmstead, Ha A2, the same phase as Březnice). `historical_status: provisional_reconstruction`.

Brief: `content/research/museum-lba/HOUSE-BRIEF.md` v1 (owner decisions 2026-11-20), card `team/museum-kanban/tasks/SB-023.md` (part 1: assets only). Evidence behind the brief rows is in `D-houses-czech-sources.md` and `D-houses-recon.md` (not re-read here). Quotations marked "brief" are literal text of HOUSE-BRIEF.md v1. The central hearth and the 0.8–0.9 m door range are **not** in the brief: they come from the manager's SB-023 phase-1 assignment (2026-11-20; not stored in the repo) and are recorded as F design choices.

## Evidence classes

| Item | Class | Basis |
|---|---|---|
| Above-ground, post-built, rectangular house | A (choice) | brief row "Type": Jiráň 2008, 169–171; Chvojka 2009, 130 |
| Footprint about 8.5 × 5 m, three rows of posts; rooms not stated | A, R/F | brief row "Footprint B": Beneš 1995 via Jiráň 2008, 169–171. Beneš 1995 not read at source. |
| Post rows: two wall rows (long-wall posts at about 1.4 m spacing) and a central ridge-post row (gable centre posts plus internal posts at x = ±2.1) | row count A (brief); positions **F** | own layout |
| Interior not divided | **F** | brief: "rooms not stated"; an undivided room is the simplest reading |
| Hearth central at the origin, no paving | **F** | design choice from the manager's SB-023 phase-1 assignment (2026-11-20; not stored in the repo); HOUSE-BRIEF.md places no hearth for type B. No tie beam over the hearth |
| Walls of wattle and daub between posts, 0.18 m, partly smoothed | A (assumed) | Jiráň 2008, 171; Pleinerová and Hrala 1988 |
| Thatch roof (straw or reed) | A (assumed) | Sklenářová 2012, 66–67; no direct Bohemian evidence |
| Roof form gabled, pitch 45° (underside), eave 2.2 m, ridge 5.09 m (underside 4.70 m), overhang 0.45 m, thatch 0.24–0.38 m, turf ridge roll | **F** | brief row "Wall height, ridge height, roof pitch": "Not known" (U); values recorded as F in `asset.json`. Steep pitch chosen as usual for thatch. |
| No windows | owner decision | no evidence in Bohemia (Sklenářová 2012, 71) |
| One door in the long +Z wall, centre x = 2.1 m, clear 0.85 × 1.60 m, no leaf | **F** (brief: "One, width not known"; U) | width within the 0.8–0.9 m range set by the manager's SB-023 phase-1 assignment (2026-11-20; not stored in the repo), not by the brief or the owner; position own choice |
| Smoke through the thatch; no chimney or smoke hole | U (brief) | — |
| Tie beams at x = ±4.25, ±2.1, wall plates, ridge beam, 11 rafter pairs | **F** | own design |
| Daub finishes (separate GLBs): `plain`; `limewash` (whitened coat, a few flaked areas); `pattern` (white geometric frieze on a darker ground) | trial: E for the existence of painted plaster; **F** for colour, motif and placement | brief row "Surface": Praha-Bubeneč plaster fragments (Sklenářová 2012, 115; Filip 1940 not read). The frieze motif is invented; **where the pattern was on a house is unknown**. |
| Anchors (`entry`, `door_inside`, `hearth_spot`, `interior_center`, `label_anchor`, `store_spot_1..3`) | F | placement suggestions, measured clear of posts and walls (`checks/spatial_check.json`) |
| Floor | not modelled | brief: "Tamped or clay-smeared earth (visible only in cutaway)"; no floor mesh (as HOUSE-002) |
| `interior_center` anchor at (0, 0, 0) | F | interior centre; coincides with `hearth_spot` because the hearth is central |

## Known limits

- Door clear height 1.60 m. The lowest eave edge is 1.741 m, about 4 cm above a 1.70 m PERSON-001, so people stoop at the door. HOUSE-002 r001 had a 1.50 m door. These are F values for phase 2 to check against the museum's walk paths (`asset.json` → `deviations`).

## Original vs third-party

- Geometry, generator, textures and previews are original project work by the AI modelling agent. No third-party meshes, textures or photos are incorporated (`incorporated_resources: []`). No CC BY-SA image was used, traced or committed.
- Mesh split, roof recipe and texture recipe are adapted from HOUSE-002 r001 (`art/returns/economy-batch5/HOUSE-002/r001/source/gen_house002.py`, same project); `source/inspect_glb.py` is copied from HOUSE-002 r001 with the changes listed in its header.
- Licence: **unselected**, a manager/owner decision.
- Fixtures used read-only, not incorporated: PERSON-001 r002 `model.glb` and KILN-001 r001 `asset.json` (hearth_base anchor offsets). SHA-256 of every input: `asset.json` → `fixture_hashes`; sources in `reference_ids`.
- Type A (HOUSE-004 r001) is built by the same generator; both returns carry byte-identical copies of the shared source files.
