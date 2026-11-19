# SLEEP-001 r001 — provenance

Brief: `art/briefs/economy-batch8/SLEEP-001.md` (economy batch 8 proposal, not a frozen pack) with
`art/briefs/economy-batch8/README.md`, the shared rules in `art/briefs/economy-batch4/README.md` (incl. the
character-motion rules) and the opus-v2 contract `COMMON.md` / `RETURN.md` (kit spec 2.0). Input hashes:
`checks/input_hashes.json`.

All output is `provisional_reconstruction`, `scale_basis = project_fit`, `physical_dimensions_m = null`.
Historical acceptance and any public release stay with the manager/owner. Original-project licence:
**unselected**.

## Evidence used (E / R / F)

The brief states the boundary: **interior furnishing unattested; bedding R**. The research files were read with
`git show` from the research branches (hashes in `checks/input_hashes.json`):
`docs/economy-research:content/research/economy/{README,subsistence,crafts-exchange}.md` and
`docs/next-batch-research:content/research/next-batch/{README,material-culture,settlement-features}.md`.
Nothing in them describes beds, bedding, sleeping places or sleeping posture. No other source was opened, no
reference image is cited by the brief, and no image was copied.

| Item | Label | Basis (exact locator) |
|---|---|---|
| Beds, bedding, interior furnishing at Březnice | **not attested** | brief line "Evidence: interior furnishing unattested; bedding R" |
| Straw as a crop by-product; bedding listed among by-product uses | **E** (straw/chaff by-product) / **R** (bedding use) | `subsistence.md` activity table row "By-product reuse \| chaff/straw → clay temper, daub, fodder, bedding" (line 349): the cited evidence covers temper (C19 p. 295; S22 p. 8) and fodder (H15), not bedding |
| Hides as an animal output | **R** | `subsistence.md` F10 outputs "animal → meat portions + hide" (line 526) |
| Leather/hide survival | **E (negative)** | `crafts-exchange.md` §2.5 "Bone/antler/leather not recoverable locally (acid soil)" (line 97) |
| HOUSE-001 footprint vs regional house type | **flag** | `settlement-features.md` line 57 and next-batch `README.md` line 30: HOUSE r001 3.6 × 3.0 m is much smaller than the 5–8 m wide regional type; the two beds fill most of its floor |
| `bed_straw`: coarse sack stuffed with straw, tied ends, cattle hide cover, rolled fleece at the head | **R** | design choice; sack fabric unspecified |
| `bed_hide_pile`: bracken/straw litter heap, large hide, two sheepskins, folded fleece head rest | **R** | design choice (bracken as litter is a game-fit choice, not sourced) |
| `bedding_rolled`: hide and fleece rolled and tied for storage | **R** | design choice |
| Sizes (mattress ~1.9 × 0.8 m per the brief; surface 0.16 m; head rest 0.195 m), colours | **R** | brief size + game fit to the 1.70 m PERSON |
| Lying down (squat → sit on the edge → roll back), supine sleep with one breath per 4 s, getting up (roll → sit → push up) | **R** | no source describes posture or sleeping habits |
| Bed positions in HOUSE-001, who sleeps where, night hearth embers | **F** | demo placement only |

## Inputs and fixtures (read-only)

| Input | Use | SHA-256 |
|---|---|---|
| `art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/model.glb` | byte comparison of the character; 1.70 m scale figure in previews | in `checks/input_hashes.json` |
| `…/PERSON-001/r002/source/person_001.blend`, `gen_person.py`, `person_palette.png` | **copied unchanged** to `source/fixture_PERSON-001_r002/source/` (copies verified identical); the rig, skin, mesh and palette of `person_sleep.glb`; the r002 pose solver is executed unchanged | same |
| `art/handoffs/bronze-bohemia-opus-v2/fixtures/HOUSE-001/model.glb` | demo house (Roof node hidden = roof off); interior x ±1.62 m, z ±1.32 m measured from its Wall mesh | same |
| `art/handoffs/bronze-bohemia-opus-v2/fixtures/POT-001/model.glb` | preview context | same |
| `art/returns/bronze-bohemia-v3/KILN-001/r001/models/hearth_open_top.glb`, `fire_embers.glb` | preview context (night hearth) | same |

HOUSE-002 exists only on branch `art/house-002-r001` (not merged into the integration branch this job was
cut from), so the brief's "HOUSE-001 only" case applies. Fixtures were copied into a throwaway Godot project
outside the repository; none is shipped in `models/`.

## Original work

All prop geometry, the procedural atlas (`source/textures/sleep_atlas.png`, painted with seeded numpy noise and
strokes), the three clips and every script in `source/` are original project work by the GitHub Copilot
modelling agent for this job. The check/preview pipeline was adapted from the same project's VISIT-001 r001
return (private project material). No third-party media, meshes or textures are incorporated.
