# LOOM-001 r001 — provenance

**Status:** draft R study for a weaving work spot. `historical_status=provisional_reconstruction`, `scale_basis=project_fit`, `physical_dimensions_m=null`.

## Evidence boundary

- **No loom is securely demonstrated in situ at Březnice.** The brief (material-culture.md §5, "LOOM-001 r001") summarises Kuna 2022 §5.2: one pair of postholes is potentially compatible with loom size, but the association is uncertain.
- **S-CH19** (Chvojka, Menšík, Šálková & Kuna 2019, *Archeologické rozhledy* 71(2): 267–308), as summarised in `content/research/next-batch/material-culture.md` (Key fact 2, citing pp. 291–292, 300–301):
  - wear is almost only in the lower part of the weight holes;
  - classic suspension from a vertical warp-weighted loom is judged "rather unlikely";
  - most weights are hypothesised to have hung **base-up**;
  - spit-support use cannot be excluded;
  - there are no in-situ rows, and mass deposits are waste (§§2.1, 3.1, 5).
- **S-KU22** (Kuna et al. 2022) is cited from `content/research/economy/crafts-exchange.md` (pp. 4, 9–13). It interprets the long pits/trenches as post-abandonment closing deposits, not loom pits. The trench-loom association is a literature hypothesis only.
- **MC02** (`content/research/next-batch/references/MC02-loom-reconstruction-quintana.jpg`) is a Wikimedia Commons photo by Wolfgang Sauber, CC BY-SA 3.0, revision 1242831590. It shows a modern Bavarian museum reconstruction (Museum Quintana, Urnfield) of a two-post loom over a pit. It was used **only as a visual type comparator**: two leaning posts, top beam, cross rods, and weights hanging low. No pixels, proportions or textures were traced or copied. No pit is modelled.
- Research note (economy F4/F7, crafts-exchange.md): a household loom "wants 24 weights" (R). This return follows the brief's 18.

## E / R / F per part

| Part | Label | Note |
|---|---|---|
| Fired-clay weights: form, size, hole, colours | E-informed (via LOOMWEIGHT-001 r001) | The mesh, material and atlas are imported **unchanged** from `source/inputs/loomweight.glb`. Their own provenance is in the LOOMWEIGHT-001 r001 return. |
| Use of the weights on a loom | R | Debated in S-CH19; it is not established. |
| Base-down row (`weights_base_down`) | R | Common museum convention. |
| Base-up row (`weights_base_up`) | R (hypothesis from E wear) | S-CH19 hypothesis. Each weight is rotated 180° about its hole axis, and the tie loop bears on the base side of the hole. |
| Frame: two posts leaning 15°, beam, heddle rod on forked stubs, shed rod, lashings | R | Generic warp-weighted loom type. The dimensions come from the brief's design envelope: 1.9 m high × 1.5 m wide × 0.6 m deep. |
| Cloth roll and woven panel, 0.9 m wide, tabby texture, undyed colour | R/design | This is not evidence of fibre, weave or colour. |
| Warp: 2 layers, 9 bundles each, stylised thread count | R/stylised | The alpha-mask cards are the only `doubleSided` exception. |
| Two staggered ranks, 0.105 m pitch, tie height 0.33 m (weights ~0.23–0.43 m above the floor) | R/design | — |
| Tie loops through the holes | R | Added for contact readability. |
| `weaver_origin` 0.7 m in front | R/design (brief) | No posture or technique is claimed. |
| Village layout in previews, people | F | Preview only. |

## Original vs incorporated

- **Original project work** (licence unselected; manager/owner decision): `gen_loom.py` and all helper scripts, plus the procedural textures `loom_atlas.png` and `loom_warp.png`. The textures are generated with numpy noise and use no photo input.
- **Incorporated project asset:** LOOMWEIGHT-001 r001 `models/loomweight.glb`, byte-identical copy, from branch `art/loomweight-001-r001`, path `art/returns/bronze-bohemia-v3/LOOMWEIGHT-001/r001/models/loomweight.glb`.
- **No third-party media is embedded.**
- **Read-only fixtures:** these were used only for scale/contact previews and checks. They are copied into the throwaway Godot project and are not shipped.

## Input hashes (SHA-256)

| Input | SHA-256 |
|---|---|
| `source/inputs/loomweight.glb (copy of art/returns/bronze-bohemia-v3/LOOMWEIGHT-001/r001/models/loomweight.glb, branch art/loomweight-001-r001)` | `5c13e7effeee7d9216d5155f426217870eb7685626d6758b09a7b96c9a9127d0` |
| `art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/model.glb` | `f2be7a0f948e554974e2fb76aeda1fa583a8a4f4fe755c8469a0dbf46ae84706` |
| `art/returns/bronze-bohemia-opus-v2/PERSON-001/r002/asset.json` | `f7b53f4fcf11071247ffd3580596cccfcb9b4b774118025226e105c63c7ec34a` |
| `art/handoffs/bronze-bohemia-opus-v2/fixtures/POT-001/model.glb` | `9ea20160b718577e8091c6e91134b32bbd9c6e2379285f50371b756fe35120a0` |
| `art/handoffs/bronze-bohemia-opus-v2/fixtures/HOUSE-001/model.glb` | `14be154b4c679230e9f8c997b8a249d04aad6646846425f4a08a44e795ccc88a` |
| `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` | `8e22c54cbacf2f03ea29e78f1e88d5c99ebe42d0a8336be34c7bf7c1ae0560b2` |
| `art/handoffs/bronze-bohemia-opus-v2/RETURN.md` | `5a54eec9cd6be17861abc30d78970b36e35f08c2bafe615d3ed02a40f8165876` |
| `art/handoffs/bronze-bohemia-opus-v2/templates/kit-asset.json` | `2e49186cb1bd1f135da6a6e94867d8e7d223ff37df3acb3f50becfc0c982211c` |
| `art/briefs/economy-batch5/README.md` | `fff3ca2311a39052437dc8805835ad05af2fe74b307785939204c6645c466c70` |
| `content/research/next-batch/material-culture.md` | `36df2adc8c5ce0f6b980007252c6239a3f979c2eb2d6fa8d8e6b95bec0978636` |
| `content/research/next-batch/references/MC02-loom-reconstruction-quintana.jpg` | `5c2e9573de564866efb33485f125d425c7a429c3567c79c46c4627c8953e8de8` |

Text and UI must not state that Březnice weights came from this loom, or that trenches were loom pits. Do not label the weights "loom weights" in-game without the manager's wording decision; see LOOMWEIGHT-001.
