# LOOMWEIGHT-001 r002 — provenance

Detail revision of the single Březnice-type fired-clay weight for BREZ-007 ("Závaží: zpřístupnit detail otvoru"). It is a game prop and a technical study, **not** a replica of a find and **not** historical approval. r001 stays unchanged beside this folder.

## Basis, decisions and contract

- Card: `team/museum-kanban/tasks/BREZ-007.md` (modelling part only; museum/tour integration is card SB-056, not this revision).
- Accepted source sheet: `team/evidence/breznice/BREZ-006/README.md` (BREZ-006 modelling sheet; it cites S-CH19 = Chvojka, Menšík, Šálková & Kuna 2019, *Archeologické rozhledy* 71, 267–308, DOI 10.35686/AR.2019.11).
- Owner decisions, 2026-11-23 (relayed by the dispatching manager): specimen **A 26 664** (obj. 1/05, S-CH19 Fig. 4: 1) accepted; the hole is to sit higher and get wear of its lower edge; neutral name **„závaží“**.
- Contract followed as for r001: `art/handoffs/bronze-bohemia-opus-v2/COMMON.md`, `RETURN.md`, kit spec 2.0. Input SHA-256 values: `checks/input_hashes.json`.
- **S-CH19 was not re-opened for r002.** All M and O statements below come from the BREZ-006 sheet, with its page locators. The figures of S-CH19 are not licensed; no pixel was used.

## Evidence labels

The contract labels (E/R/F) are kept. For BREZ-007 each row also carries the BREZ-006 class:

| Label | Meaning |
|---|---|
| **M** (→ E) | Local evidence from Březnice u Bechyně as reported by the authors (text, table, captioned drawing). In r002 only **on specimen A 26 664** unless marked "find" (whole assemblage). |
| **A** (→ E, analogy) | Analogy from another site or a general principle. Not used for any r002 geometry. |
| **O** (→ R) | The BREZ-006 researcher's own reading of the drawing, not the authors' statement. |
| **R** | Reconstruction or design value chosen by the modeller (r001 or r002). |
| **E** | Bounded source observation (r001 usage, here = M for Březnice). |
| **F** | Fiction or placement. None in r002. |

## What changed against r001, and on what basis

| Feature | r001 | r002 | Label and basis |
|---|---|---|---|
| Hole height | centre y = 0.100 m, 0.355 of the height below the top | centre y = **0.1124 m**, **0.275** below the top (measured on the export: 0.2748; 42.6 mm below the top) | **O**: A 26 664 drawing, centre ~4.4 cm below the top of 16.0 cm = 0.27–0.28 (BREZ-006 §1 "Otvor", Fig. 4: 1 p. 276). Inside the **M (find)** frame: holes from the upper third to half height, mostly at the upper/middle-third boundary (S-CH19 p. 279). Owner decision: raise the hole. |
| Wear of the hole | none | lower third of the opening widened and rounded at **both** mouths; upper edge untouched | Extent **M on the specimen**: S-CH19 Tab. 2 (p. 275), A 26 664, "Stopy opotřebení v otvoru": "v dolní třetině (z obou stran)". Owner decision: add wear of the lower edge. |
| Wear size | — | radial widening up to **3 mm** at the lowest point of each mouth, fading to the plain bore **6 mm** deep; 0 at the boundary of the lower third. Measured: opening radius at the face 9.0–10.0 mm in the lower third vs 7.7–8.1 mm elsewhere (`checks/hole_wear.json`). | **R**. The authors give no size for this specimen ("V místech opotřebení jsou otvory vyhlazeny", find, p. 291). The offset line 0.5–0.6 cm under the hole on the drawing is an **O** reading whose drawing convention the authors do not explain (BREZ-006 "Neověřeno"), so it was **not** used to size the wear. The wear was deliberately kept smaller. |
| Hole facets | 8 | 12 | **R**. r001 used 8 only for the deposit budget; r002 has no deposit. The specimen's hole is round to oval (O), not octagonal. |
| Fragment, deposit | `loomweight_fragment.glb`, `loomweight_deposit.glb` | **not regenerated** | Out of BREZ-007 scope (card inputs are `loomweight.glb` and `loomweight_marked.glb`). They remain r001 assets with the r001 hole height. |
| Name | "clay weight" | „závaží“ | Owner decision. File names keep the `loomweight` identifiers of r001. |

## What is deliberately NOT modelled

| Detail | Why not |
|---|---|
| Colour, gloss, firing, clay residue, fingerprints on the wear | Not reported for A 26 664. Only whole-find statistics exist (S-CH19 p. 279, BREZ-006 §2), which must not be transferred to the piece. The r001 atlas is unchanged (pixel-identical, `checks/atlas_vs_r001.json`). |
| Wear in the upper part of the hole | Not recorded for A 26 664; upper-only wear does not occur in the find (p. 279). |
| The offset line under the hole as a deep chamfer | Uncertain trace (O, convention unexplained) — omitted. |
| Cord, rod, loom, hanging pose | Function is unresolved by the authors (pp. 291–292, 301). A standing weight is shown, as in r001. |
| Oval 12.5 × 14 mm hole, 160 mm height, wider lower body (11.8 × 11.0 cm a quarter above the base), 4 dimples on the top, breaks at the base | These belong to A 26 664 (M or O) but no decision was given to change the body, size or mark. They stay as open questions (see `team/evidence/breznice/BREZ-007/README.md`). |

## Unchanged from r001 (see r001 PROVENANCE.md)

Truncated-pyramid form (E/M find), height 0.155 m (design value inside the reported mode, R), widths, bulge, lean, twist (R), dimple of the marked variant (E-informed), colours (E qualitatively, hues R), material, atlas recipe and seed.

## Comparison r001 → r002 (measured on the exports)

| Measure | r001 | r002 | Evidence |
|---|---|---|---|
| `cord_hole` anchor | (0.00116, 0.100, 0) | (0.00131, 0.1124, 0) | `checks/glb_inspect.json`, `checks/godot_check.json` |
| Opening radius at the face, lower third (front / back) | 7.4–7.7 / 7.4–7.7 mm | 8.0–10.0 / 8.0–9.9 mm | `checks/hole_wear.json` |
| Opening radius at the face, rest | 7.4–7.7 / 7.4–7.7 mm | 7.7–8.1 / 7.7–8.1 mm | same |
| Surface below the local face 9.5 mm from the axis, lower third, max (front / back) | 0.01 / 0.01 mm | 1.71 / 1.26 mm | same |
| Triangles `loomweight.glb` / `loomweight_marked.glb` | 176 / 226 | 256 / 306 (budgets 300 / 330) | `checks/glb_inspect.json` |
| Volume | 819.28 cm³ | 819.31 cm³ | same |
| Bounds | 0.09595 × 0.155 × 0.08752 m | identical | same |

## Original and third-party inputs

- Original project work: all geometry, scripts and the atlas (regenerated from the r001 recipe, pixel-identical). Licence **unselected** (owner decision).
- Third-party media incorporated: none. No PERSON/POT/HOUSE fixture is used in r002.
- r001 files read only (hashes in `checks/input_hashes.json`): models, generator, atlas, PROVENANCE, asset.json.
- Software: bpy 5.0.1 (PyPI, via uv, Python 3.11) with Khronos glTF I/O 5.0.21; Godot 4.5.1-stable (Compatibility/OpenGL, Mesa Intel UHD 620); Python 3, numpy, Pillow.

## Wording boundary

Use „závaží“ in game text (owner decision). Do not call it „tkalcovské závaží“ and do not show it on a loom. Text for SB-056 must keep three things apart: this find (A 26 664 and the wear recorded on it), the authors' weaving hypothesis (base-up tying, doubted classic loom suspension, spit-support use not excluded), and the separate spinning exhibit named in the card (not checked here).
