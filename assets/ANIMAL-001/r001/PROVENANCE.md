# ANIMAL-001 r001 — provenance

## Status

ANIMAL-001 r001 is the first livestock kit: `models/cattle.glb` and `models/sheep.glb`. Each is a rigged low-poly quadruped with six in-place clips. `historical_status = provisional_reconstruction`, `scale_basis = project_fit` and `physical_dimensions_m = null`. The brief is a **draft** (`content/research/next-batch/settlement-features.md` §6, "proposals, not frozen"). It was executed under the opus-v2 `COMMON.md`/`RETURN.md` contract. Technical completion here is not historical approval.

## Author and licence of this work

- **Author:** GitHub Copilot autonomous modelling agent (dispatched as the "Opus 5.5" slot) for the Bronze Bohemia project. `source/gen_animals.py` generated every vertex, bone, weight, keyframe and atlas pixel. No external mesh, scan, photograph, motion capture or texture was used or adapted.
- **Licence:** unselected original project work. The manager/owner decides; this revision does not grant a public licence.
- **Tools:** Blender 5.2.3 LTS (glTF I/O 5.2.41), Godot 4.5.1.stable.official.f62fdbde1 (Compatibility renderer, OpenGL 4.1 Metal-90.5, Apple M1 Pro), Python 3.9.6 with numpy 1.26.4 and Pillow 11.3.0, ffmpeg 9.0.2, macOS 26.7.1.
- **Project code reused:** the overall check pipeline pattern follows the accepted opus-v2 WORK-001 r001 return: throwaway Godot project, A/B import configurations, `set_import.py`-style `.import` edits, and the GPU capture scene with the same background, ambient and sun direction/energy (shadow bias differs, see CHECKS.md). The ANIMAL scripts were written fresh for this job; no WORK file was copied verbatim.

## Incorporated resources

None. `source/textures/animal_atlas.png` (512×512) is written by the generator from colour tables (`COAT`, `CELLS`) and a deterministic value-noise function. It contains no photo-derived pixels. Both GLBs embed the same bytes (SHA-256 `1e5b85ce…b0e2` for the file, `checks/glb_inspect.json` for the embedded copy).

## Sources and how they were used

| ID | Source (as recorded in `settlement-features.md` §1/§8) | Used for | Class |
|---|---|---|---|
| S22 | Šálková et al. 2022, *Sci. Rep.* 12:20323, p. 12 (CC BY 4.0) | No animal bones survive at Březnice (acid soil). Any animal shown there is a regional reconstruction. | E (negative) |
| S22 | Same, p. 9 and p. 5 (authors' inference) | Behaviour context only: grazing in enclosures and opened forest, regulated grazing. It sets no animation parameter. | R |
| KY16 | Kyselý 2016, *Živa* 2016/5 (cite only; reprint forbidden) | Species choice. Cattle are usually dominant and sheep are commoner than goats in Bohemian/Moravian prehistoric assemblages. No chickens or cats. Nothing was copied. | E (regional), species only |
| Draft brief | `settlement-features.md` §6 ANIMAL-001 r001 | Size envelopes (cattle withers 1.05–1.20 m, length ~1.8 m; sheep withers 0.55–0.65 m), budgets, bone naming, clips, anchors and acceptance. | R/design |

I did not open S22 or KY16 myself in this session. Their statements above are quoted from the research document's per-candidate notes (§3), which records full-text inspection. **No reference image was used.** The research pass found no freely licensed Bohemian Late Bronze Age faunal image or verified ancient-breed reference (§3), so none of the MC01–MC13 or SF01–SF05 pictures applies to this job. I opened the directory listing and both registries (`MCregistry.json`, `SFregistry.json`) to confirm that no animal reference is listed. Because nothing was adapted, CC BY-SA terms do not attach through those references.

## Evidence classification (E / R / F)

- **E (negative):** no faunal remains at Březnice. Nothing in the shapes is site evidence.
- **E (regional, species level only):** cattle and sheep as the two first livestock species.
- **R (all modelled content):**
  - body size and proportions;
  - short forward-curving horns on the cattle; a polled (hornless) sheep;
  - short tail and fleece silhouette;
  - four restrained coat colours per species (deliberately plural, no breed livery);
  - gait (lateral-sequence walk at an authored 0.8 m/s);
  - lying sternal with folded legs; the lie-down sequence (front knees first) and rise sequence (hindquarters first);
  - grazing posture.
  
  The brief's warning is followed: these are small, lean, generic forms, not modern breeds and not Heck cattle.
- **F:** only demo placement and herd composition in the previews (4 cattle + 8 sheep, one PERSON, HOUSE/POT context). No fence or pen is shown or implied.

## Fixtures (read-only; copied into throwaway projects/scenes only)

SHA-256 values as recorded in `checks/input_hashes.json`:

| Fixture | SHA-256 |
|---|---|
| PERSON-001 `model.glb` (r001, 1.70 m) | `a72da131e98c532bf0db6934bd70568fc5d1083d9c3fcd8d11f4083f52cccc12` |
| POT-001 `model.glb` | `9ea20160b718577e8091c6e91134b32bbd9c6e2379285f50371b756fe35120a0` |
| HOUSE-001 `model.glb` | `14be154b4c679230e9f8c997b8a249d04aad6646846425f4a08a44e795ccc88a` |

Values are copied from `checks/input_hashes.json`, which also lists the fixtures' `asset.json` files and the contract/brief files read. No fixture file is included in this return or modified; previews use copies of the GLBs only.
