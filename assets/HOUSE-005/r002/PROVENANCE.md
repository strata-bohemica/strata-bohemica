# HOUSE-005 r002 (type B) — provenance

> **Provisional reconstruction, not a plan of a Březnice house.** No complete house plan is verified at Březnice, and no unambiguously proven residential post house is known in South Bohemia (Chvojka 2009, 130, via the brief). Type B follows the **Liptice farmstead dwelling** (about 5 × 8.5 m, three rows of posts; a Knovíz farmstead; the dating conflicts within the source (stage K V–VI = Ha A2/Ha B1 to Ha B1 in Jiráň 147 and 169, the fig. 98 caption says Ha A2) and overlaps Březnice, Ha A2–A2/B1, at best, as in HOUSE-BRIEF v1). `historical_status: provisional_reconstruction`.

Brief: `content/research/museum-lba/HOUSE-BRIEF.md` v1 (owner decisions 2026-11-20), cards `team/museum-kanban/tasks/SB-023.md` (r001, part 1: assets only) and `SB-033.md` (r002, phase 2: models; research `content/research/museum-lba/E-house-tool-traces.md`). Evidence behind the brief rows is in `D-houses-czech-sources.md` and `D-houses-recon.md` (not re-read here). Quotations marked "brief" are literal text of HOUSE-BRIEF.md v1. The central hearth and the 0.8–0.9 m door range are **not** in the brief: they come from the manager's SB-023 phase-1 assignment (2026-11-20; not stored in the repo) and are recorded as F design choices.

## Evidence classes

| Item | Class | Basis |
|---|---|---|
| Above-ground, post-built, rectangular house | A (choice) | brief row "Type": Jiráň 2008, 169–171; Chvojka 2009, 130 |
| Footprint about 8.5 × 5 m, three rows of posts; rooms not stated | A, R/F | brief row "Footprint B": Beneš 1995 via Jiráň 2008, 169–171. Beneš 1995 not read at source. |
| Post rows: two wall rows (long-wall posts at about 1.4 m nominal spacing (r002: each shifted by a seeded ±0.13 m)) and a central ridge-post row (gable centre posts plus internal posts at x = ±2.1) | row count A (brief); positions **F** | own layout |
| Interior not divided | **F** | brief: "rooms not stated"; an undivided room is the simplest reading |
| Hearth central at the origin, no paving | **F** | design choice from the manager's SB-023 phase-1 assignment (2026-11-20; not stored in the repo); HOUSE-BRIEF.md places no hearth for type B. No tie beam over the hearth |
| Walls of wattle and daub between posts, 0.18 m, partly smoothed | A (assumed) | Jiráň 2008, 171; Pleinerová and Hrala 1988 |
| Thatch roof (straw or reed) | A (assumed) | Sklenářová 2012, 66–67; no direct Bohemian evidence |
| Roof form gabled, pitch 45° (underside), eave 2.2 m, ridge 5.09 m nominal (underside 4.70 m; the r002 ridge roll sags and swells, measured top 5.114 m), overhang 0.45 m, thatch 0.24–0.38 m, turf ridge roll | **F** | brief row "Wall height, ridge height, roof pitch": "Not known" (U); values recorded as F in `asset.json`. Steep pitch chosen as usual for thatch. |
| No windows | owner decision | no evidence in Bohemia (Sklenářová 2012, 71) |
| One door in the long +Z wall, centre x = 2.1 m, clear 0.85 × 1.75 m (r002; r001 1.60 m), no leaf | **F** (brief: "One, width not known"; U) | width within the 0.8–0.9 m range set by the manager's SB-023 phase-1 assignment (2026-11-20; not stored in the repo), not by the brief or the owner; position own choice |
| Smoke through the thatch; no chimney or smoke hole | U (brief) | — |
| Tie beams at x = ±4.25, ±2.1, wall plates, ridge beam, 10 rafter pairs (r001: 11) | **F** | own design |
| Daub finishes (separate GLBs): `plain`; `limewash` (whitened coat, a few flaked areas); `pattern` (white geometric frieze on a darker ground) | trial: E for the existence of painted plaster; **F** for colour, motif and placement | brief row "Surface": Praha-Bubeneč plaster fragments (Sklenářová 2012, 115; Filip 1940 not read). The frieze motif is invented; **where the pattern was on a house is unknown**. |
| Anchors (`entry`, `door_inside`, `hearth_spot`, `interior_center`, `label_anchor`, `store_spot_1..3`) | F | placement suggestions, measured clear of posts and walls (`checks/spatial_check.json`) |
| Floor | not modelled | brief: "Tamped or clay-smeared earth (visible only in cutaway)"; no floor mesh (as HOUSE-002) |
| `interior_center` anchor at (0, 0, 0) | F | interior centre; coincides with `hearth_spot` because the hearth is central |

| Door height, partition passage | F | r002 raises the door clear height to 1.75 m (r001 1.60 m) so that a 1.70 m person does not stoop; optional, easy to revert (`COMMON.door_height`) |

## Tool traces and irregularity (r002, SB-033)

Research: `content/research/museum-lba/E-house-tool-traces.md` (SB-033 phase 1, PR 465, three review rounds, last PASS per the card). Its section 3 table says what the model may show, section 4 what is our choice, section 5 what is unknown. **That document and the pages it cites were not re-read for this return**; the classes below are copied from it. Classes: **E** observed at a named site (never Březnice), **A** analogy applied to the model, **X** experiment, **U** unknown, **R/F** our reconstruction or free choice. Nothing here describes a house at Březnice, and no preserved Bohemian building timber, joint or tool mark is known in the sources read (section 5).

| Trace in the model | Class | What the model shows | Source (page, via the research note) |
|---|---|---|---|
| round timber default | E (Bohemia, soil traces) -> A once applied; R/F look | house posts and beams are round, unhewn or at most lightly hewn timber with a waney edge kept; the soil traces give nothing on bark or surface (E-house-tool-traces.md sections 2.2, 3 row 'Split versus hewn') | Sklenářová 2012, 134, 149 |
| axe facets and stop marks on a minority of posts | A (Must Farm, England); size and count R/F | 6 posts carry a shallow facet zone with a step (stop mark) at each end; two of them are the door jambs, hewn over their full height on the face toward the opening, and the lintel has one facet on its top; facet size, count and place are our choice (sections 3 'Axe facets', 4) | Must Farm PXA II, 206, 217-218 |
| split (D-section) post | R/F (lake-site analogy A for the use of split timber) | one internal ridge post per house is a D-section post (minority, our choice, not a Bohemian norm; hidden inside the house, visible only with the roof off) | Billamboz and Schöbel, 209, 215-216 |
| taper, slight bend and lean, uneven diameter and cut heights | A; amounts R/F | selected round timber stays fairly uniform (Must Farm piles 'very regular') but is never a perfect cylinder; the numbers (diameter 16-25 cm, lean up to 5 cm, bow up to 3 cm) are ours | Must Farm PXA II, 206; Sklenářová 2012, 149-150 |
| uneven post spacing | A; amounts R/F | wall-post spacing varies by +-0.13 m around the r001 nominal; the sources say 'uneven' without numbers (Must Farm gives 1.2-3.3 m for a round building in England) | Must Farm PXA II, 206 |
| post butts | E (Turnov flat bases, soil traces) / A | posts end with a blunt, slightly uneven butt at or just below the floor line; no pointed posts (pencil points belong to driven stakes only) | Sklenářová 2012, 20, 134 |
| axe-chopped ends, branch stubs, burls | R/F | ends are cut obliquely, some posts keep one or two short branch stubs or a burl; no source discusses knots (section 3 row 'Knots and branch stubs') | - (R/F) |
| lapped plates and ridge beam, withy lashings | A (simple joints, twisted withies) / X; placement R/F | wall plates and the ridge beam are two lapped pieces tied with twisted-withy collars with loose ends; rafters are lashed to the ridge beam on part of the pairs; no mortise-and-tenon detail (section 3 rows 'Joints', 'Lashings') | Must Farm PXA II, 218, 221; Lobisser 2018 (X); Sklenářová 2012, 51, 53, 55 |
| daub surface | E for the existence of smoothed, coloured daub and rod impressions; look R/F | hand-smoothed lumpy daub (thinner than nominal by 0-0.075 m, never thicker), sweeps, hairline cracks, repair patches, eight chipped spots per 16 m strip, each with its own place and shape, with faint rod impressions of uneven pitch; no planed or perfectly flat plaster | Sklenářová 2012, 43, 115; Pleinerová and Hrala 1988, PDF 49 |
| limewash and pattern finishes | trial (brief); E for painted plaster, R/F for look | unchanged in intent: limewash with flaking and cracks; the white geometric frieze is hand-painted (wavering lines, uneven strokes, gaps); where the pattern sat on a house is unknown | Sklenářová 2012, 115 (Praha-Bubeneč); HOUSE-BRIEF v1 'Surface' |
| thatch irregularity | R/F (Lobisser X for bundle fixing) | eave bundle ends step by 0.25-0.6 m runs (drop up to 0.085 m), thickness varies with a metre-scale field, ridge roll sags and varies in width, 3 fresh repair patches (low ragged mounds, irregular outline, edge tinted like the surrounding thatch), straw tone varies, silvering and moss in the texture; thatch only, as decided | Lobisser 2018, 'Assembly of the roof truss' (X) |
| weathering and patina | R/F (optional in section 3) | darker, damper post feet and roof eaves, silvered straw, soot toward the ridge, tone patches in vertex colours | - |
| no sawn, planed or perfectly regular surfaces | R/F (section 4 last bullet) | no plane-smoothed faces (Lobisser: 'we cannot prove that planes were common tools'; leaving them out is our choice), no octagonal posts, no uniform rods or patterns | Lobisser 2018 |

Parameters (all F, see `asset.json` → irregularity_r002): post diameter 0.16–0.25 m, lean up to 0.05 m, bow up to 0.03 m, cut-height jitter 0.03 m, wall-post spacing ±0.13 m, tie-beam and rafter jitter 0.12 / 0.09 m, daub thinner than nominal by 0–0.075 m (never thicker), share of posts with a facet zone about 20 %, one split ridge post per house, seed 2305. Not modelled: sawn or planed boards, plane-smoothed faces, pointed post butts above ground, mortise-and-tenon detail, windows.

## Budget

Limits: type A 7000 and type B 5000 triangles per model. The A limit is a **manager decision for SB-033 phase 2** (the SB-023 per-house limit of 5000 in the museum's `checks/museum_village/test_data.gd` is raised for HOUSE-004 at takeover; the manager edits it, not this return); B stays at 5000. The factor 1.5 was the manager's assignment for r002; the card SB-033 itself says only "bez zbytečného nárůstu" and names no factor or megabytes.

| | r001 | r002 | Why |
|---|---|---|---|
| Wall | 56 | 232 | the daub is refined so that it can carry uneven thickness, rounded corners and sag (a displaced mesh instead of 5 flat planes); on this short house the outer edges are up to 2.6 m, inner 3.6 m (round 1: 1.8 / 2.6 m, 402 triangles; reduced after the review) |
| Frame | 1280 | 2420 | round timber with 2–3 rings per post (taper, bow, lean), 7-sided irregular sections instead of octagons, facet zones with stop marks, branch stubs, lapped plates and ridge beam, withy lashings (no paving on this type); the same member recipe as type A, but the r001 frame of B was the leanest part (1280 triangles, 95 members now), so the ratio is larger than A's although the absolute increase (+1140) is smaller than A's (+1242); not reduced further because rings, stops and lashings are what the card asks the timber to show at close zoom |
| Roof | 912 | 1054 | uneven eave in bundle steps, thickness variation, wavy ridge roll, fresh patches |
| Total | 2276 | 3734 (1.64×; limit 5000, round 1: 3820) | hidden members were kept cheap (rafters 5-sided, tie beams straight) and rafter pairs reduced by 1 |

Imported size (Godot, museum import settings): all six models 1 190 890 → 2 372 542 bytes (+1 181 652; round 1: 2 130 451, +939 561). The scenes grow with the triangles and the per-vertex colours (patina, tone); the daub strip (2048 × 512, the pixel count of the earlier 1024²) is somewhat larger as a file because the grain is less blurred at its coarser pixel size. The pck before SB-033 was 8 676 496 B (state of main after SB-008, merge f141daa, measured by CI; not from the card, which quotes 8 658 052 B). The estimate is not a museum build.

## Deviations from the model source and known limits
1. Textures embedded as JPEG (core glTF image/jpeg, no extension) instead of PNG to keep each GLB small; the museum re-encodes them as lossy WebP on import.
2. Three GLBs per type (one per finish) with identical geometry; the timber and thatch images are identical bytes in all six GLBs, but each GLB embeds its own copy (GLB is self-contained).
3. No .blend saved: the generator is the native source (bpy from PyPI); rerun it to get the scene.
4. Anchor 'door_inside' kept (extra, as HOUSE-002).
5. Door clear height 1.75 m (r001: 1.60 m; HOUSE-002 r001: 1.50 m): an optional r002 change (F), so that a 1.70 m PERSON-001 does not stoop at the door. The thatch eave is now uneven (bundle ends drop by up to 0.085 m): the lowest eave point is measured in checks/spatial_check.json roof.eave_lowest_y.
6. Vertex colours (COLOR_0) are exported on all meshes (patina, damp at the post feet, tone patches); the museum import keeps them as vertex colours multiplied with the albedo texture. The timber texture is an atlas of three column bands (round surface, hewn facet, lashing) addressed by UV.
7. Post, rafter and tie-beam positions differ from r001 by seeded jitter (bounds in irregularity_r002.bounds_F); rafter pairs 10 (r001: 11, hidden under the thatch). Anchors are unchanged.
8. Central hearth (F) and the 0.8-0.9 m door range come from the SB-023 phase-1 assignment by the manager (2026-11-20), not from HOUSE-BRIEF.md (which places no hearth for type B and calls the door width unknown).

## Not verified

- No independent visual or historical review of r002 yet.
- The museum's own checks and walk paths were not run against r002 (no change in the museum repo).
- The page numbers in the table above come from `content/research/museum-lba/E-house-tool-traces.md`; they were not re-checked against the PDFs here.

## Original vs third-party

- Geometry, generator, textures and previews are original project work by the AI modelling agent (r002: Claude Sonnet 5.5 per the session system prompt, not independently verified). No third-party meshes, textures or photos are incorporated (`incorporated_resources: []`). No CC BY-SA image was used, traced or committed.
- Mesh split, roof recipe and texture recipe are adapted from HOUSE-002 r001 (`art/returns/economy-batch5/HOUSE-002/r001/source/gen_house002.py`, same project); `source/inspect_glb.py` is copied from HOUSE-002 r001 with the changes listed in its header.
- Licence: **unselected**, a manager/owner decision.
- Fixtures used read-only, not incorporated: PERSON-001 r002 `model.glb` and KILN-001 r001 `asset.json` (hearth_base anchor offsets). SHA-256 of every input: `asset.json` → `fixture_hashes`; sources in `reference_ids`.
- Type A (HOUSE-004 r002) is built by the same generator; both returns carry byte-identical copies of the shared source files.
- r002 builds on the r001 generator of the same project and on `content/research/museum-lba/E-house-tool-traces.md` as the research input (fixture hash in `asset.json`). No third-party mesh, texture or photo was used for the tool traces; the look of facets, lashings and cracks is drawn from numpy noise and own shapes.
