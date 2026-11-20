# HOUSE-004 r001 (type A) — provenance

> **Provisional reconstruction, not a plan of a Březnice house.** No complete house plan is verified at Březnice, and no unambiguously proven residential post house is known in South Bohemia (Chvojka 2009, 130, via the brief). Type A follows the plan of **Březno u Loun house 57**, whose dating is doubtful: the excavator (Pleinerová) is not sure of it and also considers the Migration Period. `historical_status: provisional_reconstruction`.

Brief: `content/research/museum-lba/HOUSE-BRIEF.md` v1 (owner decisions 2026-11-20), card `team/museum-kanban/tasks/SB-023.md` (part 1: assets only). Evidence behind the brief rows is in `D-houses-czech-sources.md` and `D-houses-recon.md`. Values not in the brief are cited to `D-houses-recon.md` (the record of Pleinerová and Hrala 1988, PDF pages) or to the manager's SB-023 phase-1 assignment (2026-11-20; not stored in the repo); quotations marked "brief" are literal text of HOUSE-BRIEF.md v1.

## Evidence classes

| Item | Class | Basis |
|---|---|---|
| Above-ground, post-built, rectangular house | A (choice) | brief row "Type": Jiráň 2008, 169–171; Chvojka 2009, 130 |
| Footprint 15 × 5.5 m; three rooms of unequal size; hearth in the largest (9 m) east room, pebble-paved, on the axis | A, R/F | brief row "Footprint A": Pleinerová and Hrala 1988; Sklenářová 2012, 114. Dating of the original plan doubtful. |
| Room split: partitions at x = −1.5 and −4.0 → east 9.0 m, middle 2.5 m, west 3.5 m outer (3.23 m clear) | R/F | brief: "3 rooms of unequal size; hearth in the largest (9 m) east room". Middle and west room sizes are not in the brief: house 57 has a middle room about 2.5 × 5.5 m and a west room 3 × 5.5 m (`D-houses-recon.md`, Pleinerová and Hrala 1988, PDF pp. 55–56, 167). The partition lines are F; with the 15 m total they leave the west room 0.5 m longer than at house 57 (deviation) |
| Hearth on the axis 7.5 m from the east end = model origin; pebble paving ellipse ≈1.9 × 1.6 m, 46 pebbles | "on the axis", "pebble-paved": A (brief); 7.5 m from the east end: E for house 57, A here; paving size and pebbles F | brief; 7.5 m: house 57 pit 243 (`D-houses-recon.md`, Pleinerová and Hrala 1988, PDF pp. 55–56), not in the brief; paving: own design |
| Walls of wattle and daub between posts, 0.18 m, partly smoothed | A (assumed) | Jiráň 2008, 171; Pleinerová and Hrala 1988 (little daub at Březno: perhaps only parts plastered) |
| Thatch roof (straw or reed) | A (assumed) | Sklenářová 2012, 66–67; no direct Bohemian evidence |
| Roof form gabled, pitch 45° (underside), eave 2.2 m, ridge 5.34 m (underside 4.95 m), overhang 0.45 m, thatch 0.24–0.38 m, turf ridge roll | **F** | brief row "Wall height, ridge height, roof pitch": "Not known" (U); values recorded as F in `asset.json`. Steep pitch chosen as usual for thatch. |
| No windows | owner decision | no evidence in Bohemia (Sklenářová 2012, 71) |
| One door in the long +Z wall, centre x = 3.0 m (east room, east of the hearth), clear 0.85 × 1.60 m, no leaf | **F** (brief: "One, width not known"; U) | width within the 0.8–0.9 m range set by the manager's SB-023 phase-1 assignment (2026-11-20; not stored in the repo), not by the brief or the owner. Position: own choice that departs from house 57, where doubled posts at the partition and no posts on the north side of the middle room suggest a possible entrance to the **middle** room (`D-houses-recon.md`, PDF pp. 55–56, 167); see Deviations |
| Smoke through the thatch; no chimney or smoke hole | U (brief) | — |
| Post layout: long-wall posts every 1.5 m, gable posts at z = ±1.4, gable centre posts, internal ridge posts at x = −4.0, −1.5 (partitions) and 4.0, partition posts at z = ±1.4; tie beams, wall plates, ridge beam, 18 rafter pairs | **F** | own design; the brief does not give post positions for this model. The central ridge-post row conflicts with the source: house 57 is **not three-aisled** (except perhaps the unclear west end; `D-houses-recon.md`, PDF pp. 167–170). A middle row of roof-beam posts is only partly preserved at **Praha-Čakovice** (Soudský 1966, via Pleinerová and Hrala 1988, PDF p. 168; `D-houses-VERIFICATION.md`). See Deviations |
| Partitions: daub panels 0.14 m up to the tie beams (y 2.2), open above; 1.0 m passage at z 0.2–1.2, 1.70 m clear | **F** | the brief gives only "3 rooms"; house 57 has doubled posts at the partition (`D-houses-recon.md`, PDF pp. 55–56). Panel form, height and passages are unknown |
| Daub finishes (separate GLBs): `plain`; `limewash` (whitened coat, a few flaked areas); `pattern` (white geometric frieze on a darker ground) | trial: E for the existence of painted plaster; **F** for colour, motif and placement | brief row "Surface": Praha-Bubeneč plaster fragments (Sklenářová 2012, 115; Filip 1940 not read); Březno u Loun black-grey and reddish plaster. The frieze motif (lines, zig-zag, hatched triangles, dots) is invented; **where the pattern was on a house is unknown**. |
| Anchors (`entry`, `door_inside`, `hearth_spot`, `interior_center`, `label_anchor`, `store_spot_1..3`) | F | placement suggestions, measured clear of posts and walls (`checks/spatial_check.json`) |
| Floor | not modelled | brief: "Tamped or clay-smeared earth (visible only in cutaway)"; no floor mesh (as HOUSE-002) |

## Deviations from the model source (house 57) and known limits

1. **Central ridge-post row (F).** The model has internal ridge posts at x = −4.0, −1.5 and 4.0 plus the gable centre posts. House 57 is not three-aisled (`D-houses-recon.md`, Pleinerová and Hrala 1988, PDF pp. 167–170). The row is a structural choice for the 5.5 m span. The only Knovíz support is Praha-Čakovice, with a partly preserved middle row of roof-beam posts (PDF p. 168).
2. **Door in the east room (F).** The source hints at an entrance in the middle room (doubled partition posts, no posts on its north side; PDF pp. 55–56, 167). The model puts the door at x = 3.0 in the east (hearth) room.
3. **West room 3.5 m outer / 3.23 m clear** against house 57's 3 × 5.5 m west room. The brief gives only the 9 m east room and the 15 m total.
4. **Known limitation for phase 2:** door clear height 1.60 m and partition passages 1.70 m clear. The lowest eave edge is 1.744 m, about 4 cm above a 1.70 m PERSON-001, so people stoop at the door and in the passages. HOUSE-002 r001 had a 1.50 m door. These are F values; phase 2 should check them against the museum's walk paths.

All four are also listed in `asset.json` → `deviations`.

## Original vs third-party

- Geometry, generator, textures and previews are original project work by the AI modelling agent. No third-party meshes, textures or photos are incorporated (`incorporated_resources: []`). No CC BY-SA image was used, traced or committed.
- Mesh split, roof recipe and texture recipe are adapted from HOUSE-002 r001 (`art/returns/economy-batch5/HOUSE-002/r001/source/gen_house002.py`, same project); `source/inspect_glb.py` is copied from HOUSE-002 r001 with the changes listed in its header.
- Licence: **unselected**, a manager/owner decision.
- Fixtures used read-only, not incorporated: PERSON-001 r002 `model.glb` (scale checks, previews) and KILN-001 r001 `asset.json` (hearth_base anchor offsets for the clearance check). SHA-256 of every input: `asset.json` → `fixture_hashes`; sources in `reference_ids`.
- Type B (HOUSE-005 r001) is built by the same generator; both returns carry byte-identical copies of the shared source files.
