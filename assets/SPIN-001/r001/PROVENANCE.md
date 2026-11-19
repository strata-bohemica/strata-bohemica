# SPIN-001 r001 — provenance

## Brief and contract

* Brief: `art/briefs/economy-batch5/SPIN-001.md` (SHA-256 `f9ec148e…dad6`) and `art/briefs/economy-batch5/README.md` (`fff3ca23…6c70`). The backlog is a proposal, not a frozen pack.
* Shared rules: `art/briefs/economy-batch4/README.md`, read from the PR #30 branch copy (`fe88072c…40ec`), plus `art/handoffs/bronze-bohemia-opus-v2/COMMON.md`, `RETURN.md` and `templates/kit-asset.json` (spec 2.0).
* All hashes: `checks/input_hashes.json`.

## Evidence classes (E / R / F)

| Item | Class | Source and locator | What it does **not** establish |
|---|---|---|---|
| Ceramic spindle whorls in Bohemian prehistory | E (general, regional) | MC11: Zde, *Spindles, pottery, Neolithic to Bronze Age, City of Prague Museum* (Wikimedia Commons, CC BY-SA 4.0), registered in `content/research/next-batch/references/` (SHA-256 `11f41642…affd`); `content/research/next-batch/material-culture.md` §SPIN-001 and table row MC11 | An LBA date for any piece shown, a Březnice whorl, whorl size, or shaft form. No Březnice whorl was identified in the inspected data. |
| Whorl form (biconical, ~42 mm, fired grey-brown clay, low on the shaft) | R | Proportions only loosely follow the biconical/drum whorls visible in MC11. The image was viewed. No pixels were copied or traced. | Exact size, weight, decoration or low/high-whorl use |
| Wool as the fibre | E (regional) → R | KY16 (Kyselý 2016, *Živa* 2016/5, p. 227, via `content/research/economy/subsistence.md` lines 241–246: sheep give wool; spinnable wool in Europe from the 3rd millennium BCE). Flax is not in the Březnice crop list: E-negative (`crafts-exchange.md` §2.3, S-SA22 p. 6; S-PO24 pp. 181, 184). | Local sheep (animal bones do not survive in the acid soil), wool colour, fleece type or processing |
| Undyed cream and natural-brown wool colours | R | Brief: “default undyed wool look” | Dyeing practice and actual fleece colours |
| Spindle shaft, yarn cop, yarn leader | R | Organic; nothing survives | — |
| Distaff (0.83 m stick + combed-wool bundle) | R | Organic; brief: “stick ~0.8 m with a fibre bundle” | Whether distaffs were used locally |
| Fibre basket and yarn balls/skein | R | Basket weave logic reused from GATHER-001 r001 (also R) | — |
| Spinning posture, drafting cycle, wrist flick, walking while spinning | R | Brief; `crafts-exchange.md` §F7 (“a villager spins thread with a hand spindle while sitting or walking between tasks”, R) | Any measured technique. Spin rate is slowed for 30 fps readability. |
| Who spins, where and when (demo scenes) | F | — | — |

All output is `provisional_reconstruction`, `scale_basis = project_fit`, and `physical_dimensions_m = null`.

## Original and third-party inputs

| Input | Use | Hash |
|---|---|---|
| PERSON-001 r002 `source/person_001.blend`, `source/gen_person.py`, `source/person_palette.png` | Copied unchanged into `source/fixture_PERSON-001_r002/source/`. `gen_spinning.py` opens the blend copy and executes the pose solver without its `main()` call. The mesh, skin, bind pose, materials, palette and `carry_anchor` are reused unchanged. | `b2138f90…7963`, `61b95fd8…2d32928`, `9f2b4fc1…c22fe` (copies byte-identical, `checks/input_hashes.json`) |
| PERSON-001 r002 `model.glb` | Byte comparison of the character (`checks/glb_inspect.json` → `fixture_comparison`). Also the standing 1.70 m scale figure in the previews. | `f2be7a0f…4706` |
| HOUSE-001 and POT-001 fixtures | Village-angle scale previews only | `14be154b…c88a`, `9ea20160…20a0` |
| VEG-001 r001 `oak_autumn.glb`, ANIMAL-001 r001 `sheep.glb` | Village context in the previews only (wool source next to the spinners) | `f51ad37a…1822`, `beefdac8…11b0` |
| GATHER-001 r001 source (economy batch 4, same project) | Pipeline scripts adapted: inspector, re-import, reopen, Godot runner and check, compose. Also the trunk helper functions (`g_trunk`, `planted_legs`, `idle_arm`, `blend_arm`) and the wicker texture logic. | Read from the PR #30 branch working copy |

Everything else is original procedural work written for this job: geometry, the 512² atlas, the motions and the scripts. Nothing from the fixtures ships in `models/` except the unchanged PERSON r002 body inside `person_spinning.glb`. No third-party media is incorporated. MC11 was only viewed.

## Licence

Own work: **unselected**. This is original project work, and the manager/owner decides its licence. The fixtures are private project material, and no public sublicence is granted. Historical acceptance and any public release are the manager's or owner's decision.

## Agent

GitHub Copilot autonomous modelling agent, dispatched as the “Opus 5.5” modeller slot for job SPIN-001 r001. The underlying model identity cannot be independently verified from inside the session. Work was done in a scratch clone. Godot projects, XDG roots and raw frames were kept in a scratch folder outside the repository, because `/tmp` is not permitted in this environment.
