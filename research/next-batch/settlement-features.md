# Next batch — settlement features, animals, landscape and shared spaces

2026-11-06. Research proposal for the manager, **not historical approval and not a frozen handoff pack**. Scope: features, animals, crops and landscape elements beyond the existing HOUSE, POT, URN, TOOL, PERSON, VEG (oak/hazel/grass), WATER bank, FIELD (barley) and WORK (saddle quern) jobs. Setting as in `prototype-brief.md`: imagined household cluster inspired by Březnice near Bechyně (Tábor district), Ha A2 / Ha A2–B1, c. 1150–1000 BCE.

Evidence labels follow the existing packs: **E** = bounded observation from an inspected, identified source; **R** = reconstruction/inference/design choice; **F** = fiction. Regional comparators (West Bohemia/Milavče, Bavaria, Austria, Poland) are **not Březnice evidence**. Commons captions are leads, not museum verification. Negative verification ("not found here") means unresolved, not archaeologically absent.

## 1. Scope and method

**Read first (repo):** both handoff packs (README/COMMON/jobs/SOURCES/research-notes/registries), `content/research/*.md`, `DEVELOPMENT_PLAN.md` (target: households, fields, woodland, water, storage, shared work areas, *a few domestic animals*, eating/resting/socialising).

**Primary sources inspected this session (full text unless noted):**

| ID | Source | Access / what was read |
|---|---|---|
| K22 | Kuna, Němcová, Šálková, Menšík, Chvojka 2022, *Deposition analysis and the hidden life of Bronze Age houses*, J. Anthropol. Archaeol. 67:101433. | Publisher OA (CC BY-NC-ND 4.0) — publisher PDF blocked; full text read from the [University of West Bohemia repository PDF](https://naos-be.zcu.cz/server/api/core/bitstreams/5d93fa40-360f-4931-8205-53a35c41cb0b/content) (handle [11025/49410](http://hdl.handle.net/11025/49410)). §§2, 3.2, 5.2–5.3, Figs 3, 8 captions. **NC-ND: link and cite only; no figure copied.** |
| S22 | Šálková et al. 2022, *Extensive archaeobotanical data…*, Sci. Rep. 12:20323, [DOI](https://doi.org/10.1038/s41598-022-24753-x). | Same university PDF as the opus-v2 pack ([naos-be.zcu.cz](https://naos-be.zcu.cz/server/api/core/bitstreams/7115b54d-fe44-4a16-9a8c-ea51b7a2400d/content)); re-read Site and region (pp. 3, 5), Results (p. 6), Discussion (pp. 8–12). CC BY 4.0. |
| C19 | Chvojka, Menšík, Šálková, Kuna 2019, *Tkalcovská závaží nebo podstavce pod rožně?*, Archeologické rozhledy 71:267–308, [DOI 10.35686/ar.2019.11](https://doi.org/10.35686/ar.2019.11). | [Institute PDF](https://www.arup.cas.cz/wp-content/uploads/2019/11/4_Chvojka_267-308_web.pdf) now fetched in full (previous briefs had only excerpts): §2.1 pp. 269–270, Tab. 1, pp. 287–288, 292–296. |
| Z22 | Kuna, Němcová, Chvojka, *Sídliště z mladší doby bronzové v Březnici: data pro depoziční analýzu*, Zenodo [10.5281/zenodo.6475797](https://doi.org/10.5281/zenodo.6475797), CC BY 4.0. | `EN_comments.pdf` and table `_objekty.xlsx` (123 feature records: type code, excavated area m², max. preserved depth). Depth unit confirmed as cm by matching features 1/05 and 12/06 against C19 (both 30). |
| KY16 | Kyselý, R. 2016, *Historie chovu domácích zvířat v Čechách a na Moravě ve světle archeozoologických nálezů*, Živa 2016/5:225–229. [PDF](https://ziva.avcr.cz/files/ziva/pdf/historie-chovu-domacich-zvirat-v-cechach-a-na-mora.pdf). | Full text. Cited by S22 (ref. 103) as the regional source for Late Bronze Age domestic animals. **Academia: reprint of text/figures explicitly forbidden — cite only.** Popular-science synthesis by an archaeozoologist, not a site report. |

**Relied on prior inspection, not re-read this session:** Šálková et al. 2025, Archaeological Prospection 32:525–548 ([DOI](https://doi.org/10.1002/arp.1973), CC BY) — publisher returned a bot challenge; its storage-pit/vessel statements below come from `art/handoffs/bronze-bohemia-opus-v2/references/research-notes.md` (source B).

**Image method:** Wikimedia Commons API (User-Agent `BronzeBohemiaResearch/1.0`, ≥1–2 s between calls, backoff on HTTP 429), `imageinfo`+`extmetadata` for author/licence/description, revision IDs recorded, thumbnails requested at 1600 px (Commons served its 1920 px bucket or the smaller original). Every kept image was opened and inspected visually. Rejected after viewing: Stillfried aerial (modern landscape outline, rampart not legible; mixed CC BY / CC BY-SA statement), Vatya urn-burial drawing (Hungarian Middle Bronze Age reconstruction drawing — misleading for Knovíz), willow dune barrier (modern coastal use). Bullenheimer Berg not used (landscape only).

**Coordination note:** `references/` is shared with a parallel material-culture register (MC files). Its MC03/MC04 are byte-identical to the West Bohemian storage/large vessel photos I had selected, so I did **not** duplicate them; `SFregistry.json` cross-references them. MC13 (firedog) is relevant to KILN-001 hearth dressing.

## 2. Candidate table

Priority: **1** = propose for next batch; **2** = good follow-up; **3** = hold for more evidence or later learning layer.

| ID-proposal | Item | Game use / routine | Evidence status (Březnice unless stated) | Priority | Refs |
|---|---|---|---|---|---|
| STORE-001 | Sunken storage jar in house floor + bowl-shaped storage pit | deposit/withdraw household stores; "grain arrives at storage" loop | **E** existence, count (5), plan size of truncated features, location ~2.5 m W of long pits (probably inside houses); inherited S25 crop-absence note not re-verified here; jar profile/capacity/lid **R** | **1** | K22 §3.2, §5.2, §5.3.1; Z22; C19 Tab. 1; MC03/MC04 |
| KILN-001 | Small fired-earth oven/hearth feature (outdoor or roofed) | cooking, warming, drying, gathering; social anchor | **E** 11 features classed "pec" (burnt surface/fill), 0.2–1.3 m² excavated, 5–25 cm preserved; superstructure, function (cooking vs. pottery vs. drying) and roofing **R**; analysts disagree on some | **1** | K22 §3.2; Z22 |
| FIELD-002 | Crop variant kit: broomcorn millet, hulled wheat, legume patch | adds crop diversity to field/harvest loops; reuses FIELD-001 pipeline | **E** charred millet, barley, emmer, einkorn, spelt, free-threshing wheat, lentil, pea, broad bean; cf. oat impressions; flax **not found** in inspected sources; proportions/cultivars/heights **R** | **1** | S22 Results p. 6; C19 pp. 287–288; SF02–SF04 |
| ANIMAL-001 | Cattle + sheep (first animal kit), pig/dog follow-up | grazing, herding to/from pasture, fodder, milk; "a few domestic animals" | **E (negative)** no bones survive at Březnice (acid soil); **E (regional)** Bohemian/Moravian farming always based on cattle, pig, sheep/goat, cattle usually dominant in prehistoric assemblages, sheep > goats; horse present since Eneolithic; KY16 tentatively places early domestic fowl at the end of the Bronze Age; excluding chickens/cats is a cautious **project choice**, not evidence of local absence; breed, size, colour, herd size **R** | **1** | S22 p. 12; KY16 |
| FENCE-001 | Modular wattle hurdle + small pen/garden enclosure | animal pen, keeping animals from crops, garden plot edges | **R** at Březnice: no fence line reported; 30 small postholes recorded without published fence alignments; S22 Discussion *infers* regulated grazing "in enclosures"; wattle-and-daub house walls are regional (K22) | **2** (draft supplied: cheap enabler for ANIMAL) | S22 p. 9; K22 §5.2; Z22; SF05 |
| LONGPIT-001 | "Long pit"/trench with burnt pottery, daub and loom-weight fill | house abandonment/closing event; learning layer about the site's signature feature | **E** strong and site-specific: ~70 inferred, 15–21 excavated; 0.8–1 m wide, 3–7 m long, depth ~0.5 m (preserved 5–70 cm), N–S aligned; fill burnt at 1000–1200 °C elsewhere; **R** ritual interpretation ("closing rituals"), house link | **2** (draft supplied) | K22 §2, §5.3.3–5.3.4; C19 §2.1; Z22 |
| CLAYPIT-001 | Shallow clay-extraction pit + daub-mixing heap | house maintenance (re-plastering; up to 3 plaster layers with white coat attested), pottery making | **E** one "clay pit" (5/05), ~12 m² excavated, 30 cm preserved; **E** daub with white coating, max 3 layers; tools/mixing method **R** | 2 | K22 §3.2, §5.3.1; Z22 |
| WOOD-001 | Firewood/timber stack, kindling bundle | fuel gathering loop, seasonal stockpiling | **E** charcoal taxa (oak dominant; birch, pine, hazel, poplar/willow, fir etc.), fir mostly from stake pits, firewood "commonly available in surrounding forests"; stack form, location **R** | 2 | S22 pp. 6, 10 |
| PATH-001 | Worn footpaths/trackway decals to fields, stream, burial ground | readability of routines; route planning | **R**: fields modelled 10–15 min walk E/N; S22 states the site was "probably" on a long-distance route Alps–Central Bohemia (assumption). Engine/terrain work more than a GLB | 3 | S22 pp. 3, 8; Chvojka 2015 (not inspected) |
| BURIAL-001 | Flat urnfield cremation cemetery: urn pit, cover, pyre site | later learning layer: funerals, ancestors | **E (secondary)** a Březnice flat cemetery exists and lay beyond the northern edge of the modelled fields (S22 citing Chvojka et al. 2009, not inspected); grave form, pyre, markers **not inspected**; sensitive | 3 | S22 p. 8 ref. 93; v1 URN-001 |
| CAST-001 | Bronze casting hearth, moulds, crucible | craft scene | **Not found** at Březnice in inspected sources (no mould/crucible feature class in Z22); copper "generally assumed" imported (S22). Image SF01 is **Early** Bronze Age West Bohemia | 3 | S22 p. 3; SF01 |
| HILLFORT-001 | Rampart/palisade of a Late Bronze Age hillfort | landscape backdrop | **No LBA South Bohemian hillfort source verified this session.** Hlásek 2023 (Památky archeologické) concerns the Early→Middle Bronze Age transition — different period, not read. Hold | 3 | — |

Excluded as distinct assets: wells (none in the Z22 feature list; water access remains `WATER-001` + R route), raised granaries (no evidence found; sunken jars/pits are the attested storage form at this site), chickens (cautious project choice; KY16 does not establish local absence).

## 3. Per-candidate notes

### STORE-001 — sunken storage vessels and storage pit (priority 1)

- **E** K22 §3.2: Březnice features include "kilns (features with a burnt surface or fill), sunken storage vessels, a clay pit, unspecified pits". K22 §5.2: "five features, which we interpret as sunken storage vessels, which, with most probability, could have been originally situated inside the houses (or under a roofed structure)"; four lie ~2.5 m west of long pits, "roughly in the middle of the houses". The house link is the authors' **R**.
- **E** K22 Fig. 3 caption: feature 6/05 "interpreted as storage pit, originally with a sunken vessel". C19 Tab. 1: 4/05 "jáma s amforovitou zásobnicí" (pit with an amphora-shaped storage jar). K22 §5.3.1 (citing Chvojka et al. 2021): one feature held three storage jars "inserted into each other", read as **gradual renewal/replacement** of a sunken jar over years — a nice, defensible state change (old jar → new jar).
- **E** Z22 `_objekty`: code `O-zásobnice` = 5 features. Three small ones (2006-O-05, 2006-O-11, 2007-O-02) have excavated areas 0.15–0.35 m² and preserved depth only 5–14 cm (plough truncation, S3 in prototype brief); 2005-O-04 1.34 m²/20 cm ("filled with a storage-jar torso"); 2005-O-06 2.06 m²/60 cm ("bowl-shaped pit, storage-jar torso"). These are **truncated archaeological footprints**, not jar diameters or original depths.
- **Inherited source note, not re-verified here:** opus-v2 notes attribute a lack of stored-crop remains in sampled contexts to S25. This review did not retrieve S25; it does not establish vessel contents. Do not present game contents as E.
- **R** jar profile: broad Late Bronze Age storage-jar silhouette from West Bohemian comparators MC03/MC04 (wide belly, everted rim, cordon) — not a Březnice profile. Lid (wood/stone/clay), rim height above floor, capacity: **R**.
- **Dependencies:** HOUSE (interior placement; HOUSE r001’s 3.6×3.0m wall footprint is a design fixture; K22’s 5–8m regional width is an assumption for unobserved houses, not a Březnice measurement. Flag storage fit for design review, not automatic rescaling), POT palette, PERSON (kneel/reach clip optional; WORK grind posture may be reused).

### KILN-001 — small fired-earth oven/hearth feature (priority 1)

- **E** K22 §3.2 defines "kilns" as features with a burnt surface or fill. Z22: 11 features coded `O-pec` (five also *pec* under the second classification; a sixth, 2019-O-21, is *pec* only under the second classification) (e.g. 2019-O-19, -22, -23, -33, -34, -44, -45, 2009-O-09, 2005-O-03), excavated areas 0.2–1.31 m², preserved depths 5–25 cm. Comments include "burnt, no finds", "traces of fire", "or storage vessel" (2005-O-03). The second analyst's column classes some of the same features as "natural" or "undetermined pit" → **classification uncertain**.
- **R** what stood above: clay dome oven vs. open hearth vs. drying/firing pit is not established. A low clay-domed oven is a common prehistoric reconstruction but **not verified here**; an open hearth ring is equally defensible. Recommend one feature with two swappable tops (open hearth / low dome) and fire states, so the manager can choose after review.
- **E (related)** C19 discusses (and does not confirm) clay weights as spit supports at hearths: "the find situation and no traces on their surfaces indicate such use". Do not stage loom weights as spit supports. MC13 firedog image is a separate comparator owned by the MC register.
- **Dependencies:** PERSON (crouch/tend clip — can reuse WORK enter/exit pattern), POT (cooking pot placement), WOOD-001.

### FIELD-002 — crop variant kit (priority 1)

- **E** S22 Results p. 6: "Panicum miliaceum, Hordeum vulgare, Triticum dicoccum, Triticum monococcum, Triticum spelta, Triticum aestivum/durum/turgidum, Lens culinaris, Pisum sativum, Vicia faba", as caryopses, rachis internodes, glume bases and pulse seeds. C19 pp. 287–288: impressions in clay weights also show pea, broad bean, uncertain lentil, cf. oat (~0.5 %), plus gathered acorns, hazelnuts, sloe stones; einkorn/spelt/naked wheat/millet impressions co-occur in different contexts from barley/emmer.
- **E** S22 p. 8: drier vs. wetter field weed groups; fields modelled 10–15 min walk E/N (model output, **R** for placement).
- **E** S22 p. 12: both waste and production parts of crops found → local cultivation and processing (supports harvested/stubble state).
- **Flax:** not in S22 crop list, C19 impressions or K22 text inspected → do **not** add a flax field now (unresolved, not absent).
- **R** cultivar, heights, densities, sowing season, intercropping vs. separate plots, garden vs. field for legumes. KY16 calls millet a Late Bronze/Early Iron Age "fashion" in Czech lands — regional context, not a proportion.
- **Dependencies:** FIELD-001 kit conventions (1×1 m patch, base_center, states), PERSON.

### ANIMAL-001 — cattle and sheep (goat not modelled; priority 1)

- **E (negative)** S22 p. 12: "Animal bones were not preserved due to the acidic soil. However, for the Late Bronze Age sites the types of the domestic and the hunted animals are known" (citing KY16 and Kyselý 2005). So **any animal at Březnice is a regional R**.
- **E (regional, KY16)** farming communities in Bohemia/Moravia were always based on cattle, pig and sheep/goat; cattle usually dominant in prehistoric bone assemblages; sheep commoner than goats; hunting a small contribution from the Early Bronze Age on (KY16 chart label for the Late Bronze Age sample: "2 800/7", apparently bones/sites — not a Březnice sample); domestic horse probable from the Early Eneolithic; KY16 p.229 tentatively associates an early Central European chicken find at Ostrov-Zápy with the terminal Bronze Age and the ninth century BCE. The broad chart band is not more precise than the paragraph. Chickens remain excluded as a cautious design choice for this c.1150–1000BCE setting, not proof of local absence; cats are discussed much later. No herd ratio is inferred from the regional synthesis.
- **E (inference by authors)** S22 p. 9: grazing in enclosures and opened forests, winter fodder from near the settlement, grazing regulated to protect crops; p. 5 one family's animals "could have grazed about 6.25 ha" (model input). These are **R** for behaviour.
- **R** size, horn shape, coat colour, breed look, herd composition, milking, traction. Avoid modern high-production breeds and Heck cattle as "authentic"; keep small, lean, short-legged generic forms.
- **Images:** none adopted — no freely licensed Bohemian LBA faunal image or verified ancient-breed reference found; modern breed photos would add no evidence.
- **Dependencies:** FENCE-001 (pen), FIELD-002/VEG grass (grazing), PERSON (herding = existing walk). New quadruped rig — highest modelling cost in this batch.

### FENCE-001 — wattle hurdle and pen (priority 2, draft supplied)

- **E** Z22: 30 records coded `K` (post/stake holes, small: mostly 0.01–0.09 m²); no fence alignment is published in sources inspected. C19 §2.1: pairs of postholes inside/near long pits. S22 p. 10: fir mostly from stake pits.
- **R** S22 p. 9 "Grazing took place in the enclosures" is a discussion inference, not a reported fence feature. Woven wattle is attested in house walls regionally (K22 §5.2: "walls of wooden posts, wattle and daub" — citing other regions), so the *technique* is plausible; using it for fences is **R**.
- Image SF05 is a modern West Serbian fence — stake-and-weave construction only.

### LONGPIT-001 — long pit with burnt deposit (priority 2, draft supplied)

- **E** K22 §2: "longish narrow features (with a breadth of usually 0.8–1 m and a length of 3–7 m), their depth is usually around 50 cm, and they are uniformly aligned along the north–south axis"; ~70 inferred at Březnice from magnetometry (S22 p. 3), 15 typical excavated (K22). C19 §2.1: 1/05 = 6 m × 0.8–1 m × max 30 cm, two opposed postholes near the ends, dark burnt fill with pottery, ~28 loom weights, daub, quartz hammerstones; 12/06 = 7.3 m × 1.0–1.4 m × max 30 cm, black burnt layer at base, ≥41 loom weights. Z22 preserved depths 5–70 cm.
- **E** K22 §5.3.3: secondary burning at 1000–1200 °C happened **outside** the pits; pits filled in one step (§5.3.4). One E–W exception (3/07).
- **R** the authors' interpretation: deposits from ritualised burning/"burial" of houses at abandonment. Present as an interpretation in any learning text; do **not** make routine house burning a default animation (prototype brief already warns).

### Other candidates (brief)

- **CLAYPIT-001 (2):** K22/Z22 one clay pit 5/05, ~12 m² excavated area, 30 cm preserved; daub with up to 3 plaster layers and white coating (K22 §5.3.1). Good maintenance loop; shape is a shallow irregular scoop (**R**).
- **WOOD-001 (2):** S22 charcoal: Abies, Alnus, Betula, Corylus, Fagus, Fraxinus, Quercus, Picea, Pinus, Populus/Salix, Tilia; oak dominant; firewood from surrounding forests. Stack form/size/placement **R**. Cheap prop (≤400 tris), can be folded into KILN-001 as dressing.
- **PATH-001 (3):** better as terrain splat/decal in-engine than a modelling job.
- **BURIAL-001 (3):** need Chvojka et al. 2009 (*Archeologické výzkumy v jižních Čechách* 22:61–98) before any grave asset; reuse URN-001 when ready.
- **CAST-001 (3):** no Březnice casting evidence found; SF01 is Early Bronze Age and West Bohemian.
- **HILLFORT-001 (3):** source gap; do not model from generic "Bronze Age fort" imagery (Biskupin is Early Iron Age Lusatian, Poland).

## 4. Reference image register

Files in `references/`; machine-readable details (revision IDs, download URLs, SHA256, pixel sizes) in `references/SFregistry.json`. Credit format: “Author — Title, Wikimedia Commons, licence (link)”. All are **leads/visual guides**, not Březnice evidence.

| ID | File | Title / page | Author | Licence | SHA256 | Shows | NOT evidence of |
|---|---|---|---|---|---|---|---|
| SF01 | SF01-casting-moulds-EBA.jpg | [Stone molds for bronze casting, Museum of Western Bohemia, 187766](https://commons.wikimedia.org/wiki/File:Stone_molds_for_bronze_casting,_Museum_of_Western_Bohemia,_187766.jpg) | Zde | CC BY-SA 4.0 | 754809695eb0686c55068f6cdcad13ccb334386f32f6d4bdc32aa3a0075d4664 | stone moulds with matrices; modern experimental-melting objects (caption) | Late Bronze Age, Březnice, casting setup, dimensions |
| SF02 | SF02-millet-field.jpg | [Panicum miliaceum - white millet](https://commons.wikimedia.org/wiki/File:Panicum_miliaceum_-_white_millet.jpg) | Globe Master - SideEffect | CC BY 3.0 | d74ac6a82400b257efbf8b1f7d2c9dc241b76217a8a2a47d387ef5acfb3cc6af | modern millet plot, Biskupin museum field (PL) | ancient cultivar, height, density, layout; sign not to be modelled |
| SF03 | SF03-emmer-field.jpg | [Triticum dicoccon - emmer wheat](https://commons.wikimedia.org/wiki/File:Triticum_dicoccon_-_emmer_wheat.jpg) | Globe Master - SideEffect | CC BY 3.0 | fc87d055f427387f02e3e897d88eebcf4b2057ee0148c3451f5dd38deba694e7 | modern ripening emmer plot, Biskupin | ancient morphology; emmer dominance among the four wheats |
| SF04 | SF04-broad-bean.jpg | [Dicke Bohne (Vicia faba) dichter Bestand](https://commons.wikimedia.org/wiki/File:Dicke_Bohne_(Vicia_faba)_dichter_Bestand,_Josef_Schlaghecken.jpg) | Schlaghecken Josef | CC BY-SA 4.0 | a4e356d0b22370cd15420a4745dacb8c2bde5965d6e106be8a32870485869a21 | modern dense broad-bean foliage | prehistoric (smaller) bean, density, garden layout |
| SF05 | SF05-wattle-fence.jpg | [Wattle fence, West Serbia](https://commons.wikimedia.org/wiki/File:Wattle_fence,_West_Serbia.jpg) | Gmihail at Serbian Wikipedia | CC BY-SA 3.0 RS | 42acabd9ca93afdbc98a8583613bf6a0ee05e05cecbc916d2a43648f84aaf561 | pointed stakes with woven withy band | any Bronze Age fence; height/spacing |
| (MC03) | MC03-storage-vessel-lhotka.jpg — cross-ref | [Storage vessel, 1250-950 BC, MWB 187847](https://commons.wikimedia.org/wiki/File:Storage_vessel,_1250-950_BC,_Museum_of_Western_Bohemia,_187847.jpg) | Zde | CC BY-SA 4.0 | 2a2b553b…e45c | wide-bellied jar, everted rim, impressed neck cordon | Březnice sunken-jar profile; size |
| (MC04) | MC04-large-vessel-brdo.jpg — cross-ref | [Large vessel, 1250-950 BC, MWB 187849](https://commons.wikimedia.org/wiki/File:Large_vessel,_1250-950_BC,_Museum_of_Western_Bohemia,_187849.jpg) | Zde | CC BY-SA 4.0 | e8623dab…af2c | open-mouthed large vessel | Březnice profile; size |

Image count: 5 new (3 CC BY-SA, 2 CC BY) + 2 cross-referenced CC BY-SA. Pixel copying/texture use of BY-SA images creates share-alike obligations; study-only use preferred, as in the existing packs.

## 5. Ranking and dependencies

Score = game value × evidence × feasibility (each 1–3).

| Rank | ID | Game | Evidence | Feasibility | Notes / dependencies |
|---|---|---|---|---|---|
| 1 | STORE-001 | 3 | 3 | 3 | HOUSE interior, POT palette; first site-specific storage form |
| 2 | FIELD-002 | 3 | 3 | 3 | FIELD-001 conventions; cheapest high-value item |
| 3 | KILN-001 | 3 | 2 | 3 | PERSON tend clip; WOOD dressing; MC13 firedog cross-ref |
| 4 | ANIMAL-001 | 3 | 1–2 | 1 | new quadruped rigs; FENCE pen; grass |
| 5 | LONGPIT-001 | 2 | 3 | 3 | HOUSE abandonment event; learning layer |
| 6 | FENCE-001 | 2 | 1 | 3 | enables ANIMAL; wattle only R |
| 7 | WOOD-001 | 2 | 2 | 3 | could be folded into KILN-001 |
| 8 | CLAYPIT-001 | 2 | 3 | 3 | HOUSE maintenance loop |
| 9 | PATH-001 | 2 | 1 | engine | terrain work |
| 10 | BURIAL-001 | 1 | 1 (pending) | 2 | read Chvojka et al. 2009 first |
| 11 | CAST-001 | 1 | 0 | 2 | no local evidence |
| 12 | HILLFORT-001 | 1 | 0 | 1 | no verified LBA source |

## 6. Draft job briefs (proposals, not frozen)

All drafts inherit `art/handoffs/bronze-bohemia-opus-v2/COMMON.md` (metres, +Y up, +Z front, GLB 2.0, named anchors as exported nodes, single-sided solids, Godot 4.5.1 test, provenance, licence unselected, `scale_basis=project_fit`, `historical_status=provisional_reconstruction`, `physical_dimensions_m=null`). All dimensions below are **R/design envelopes** unless marked E. Guides/fixtures would be assembled by the manager.

### STORE-001 — canonical storage draft, HOLD (not dispatchable)

This consolidates the former POTTERY-002 sketch. **HOLD before modelling dispatch:** publish one measured or explicitly R jar profile, common floor origin, HOST floor cut polygon, lid seat/rest transforms and thickness/cavity clearances, and one final budget/file set. The numerical sketch below is research material only, not an export contract. Do not combine its anchors with the superseded POTTERY-002 anchors.

Evidence (K22/Z22/C19): five features are interpreted as sunken storage vessels, with the possible house association an author inference; one pit originally held a sunken vessel; one feature shows a jar replaced over time; sampled-store crop absence is inherited from earlier S25 notes, not independently re-verified here. Excavated footprints are plough-truncated and give no jar size. Read MC03/MC04 for broad West Bohemian storage-jar character only (wide belly, everted rim, impressed cordon) — not a Březnice profile. Lid form, capacity, floor level and contents are R.

**Research sketch only — not required exports while HOLD (4 proposed GLBs):** `models/store_jar_sunken.glb` — jar set into a floor patch; rim ~0.08 m above floor, visible jar height above floor ≤0.12 m, total jar height 0.60–0.75 m, max diameter 0.50–0.60 m; floor/earth collar disc ≤1.1 m diameter, collar top at y0. `models/store_jar_lid.glb` — separate simple lid (flat wooden/stone disc, R) ≤0.62 m. `models/store_pit_open.glb` — bowl-shaped open pit, ~1.4 m diameter × 0.6 m deep (R; consistent with, not measured from, 2005-O-06), earth rim, with one partly sunk jar; `models/store_jar_renewed.glb` — same set with a visible older broken jar rim around a newer jar (the attested replacement situation, R form). ≤700 triangles each, ≤2 materials across kit, one ≤1024² atlas. Real interior cavity and wall thickness; open mouth; no baked grain, sacks or wooden granary.

**Unfrozen anchor sketch (must resolve hold gates):** `base_center` (floor level at jar centre, y0), `mouth_center` at rim, `worker_origin` at (0,0,-0.6) facing +Z, `lid_rest` beside jar. **States:** lid on/off is a separate-node toggle, no animation in GLB. Optional demo: PERSON kneel-reach pose using the WORK grind_enter pattern (not required).

**Acceptance:** placement inside actual HOUSE fixture (floor flush, no z-fighting, door clearance), culling from above/below, close view of rim/collar, isometric readability at size 16 and 25, wireframes, measured counts/bounds from reopened exports. Historical boundary: no stored-grain display, no decorations beyond a plain cordon, no raised granary.

### FIELD-002 r001 — millet, hulled wheat and legume patches

Evidence (S22/C19): millet, barley, emmer, einkorn, spelt, free-threshing wheat, lentil, pea and broad bean present as charred remains; cultivars, heights, densities and plot arrangement unknown. SF02/SF03/SF04 are modern museum/field plants for general structure only. Flax is not included (not found in inspected sources).

**Required files (9 GLBs):** `models/{millet,wheat,legume}_{growing,mature,harvested}.glb`. Same contract as FIELD-001: mutually exclusive 1×1 m patches, ground at y0, centred, identical footprint/pivot/material slots, soil base ≤0.03 m. Design heights: millet mature 0.7–1.0 m with drooping panicles; wheat mature 0.8–1.1 m, awned ears visually distinct from barley; legume mature 0.4–0.7 m bushy leaf mass with visible pods; growing 0.2–0.4 m; harvested ≤0.15 m stubble/residue (legume harvested may show pulled plants laid in rows, R). ≤500 triangles/model, ≤2 materials across kit, ≤1024² atlas with ≤2 textures; alpha MASK cards allowed and listed, no alpha BLEND. Reuse FIELD-001's `bare` patch rather than duplicating it.

**Anchors:** `base_center`, `plot_origin`. **Acceptance:** contact sheet of all 9 + FIELD-001 barley mature at identical camera/lighting; each crop distinguishable from barley at size 25 by silhouette, not only hue; worker-circle layout test as FIELD-001; leaf culling check. Historical boundary: no monoculture claim, no proportions, no seasonal labels baked into names.

### KILN-001 r001 — fired-earth hearth/oven feature

Evidence (K22/Z22): eleven Březnice features classed as kilns/ovens by burnt surface or fill; excavated areas 0.2–1.3 m², preserved depth ≤0.25 m; classification partly disputed; superstructure and function unknown. Clay weights as spit supports are unconfirmed (C19) — do not use them as hearth furniture.

**Required files (5 GLBs):** `models/hearth_base.glb` — burnt-earth patch ≤1.2 m diameter, slight hollow ≤0.10 m, fire-reddened rim (R) — the attested part. `models/hearth_open_top.glb` — loose stone/clay ring ≤1.0 m, ≤0.15 m high (R). `models/hearth_dome_top.glb` — low clay dome ≤1.1 m wide, ≤0.65 m high, front opening ≥0.30 m, real thickness (R; alternative to open top). `models/fire_{embers,lit}.glb` — small log/ember geometry ≤0.6 m footprint; flames as restrained opaque/MASK geometry, no particles. ≤600 triangles each (fire ≤300), ≤3 materials kit-wide, ≤1024² atlas.

**Anchors:** `base_center`, `fire_center`, `pot_rest` (for POT fixture on/next to fire), `tend_origin` at (0,0,-0.8). **Optional motion study:** `person_tending.glb` with `tend_enter`, `tend` (2 s loop, poke/feed fire), `tend_exit` on an unchanged PERSON fixture copy, same rules as WORK-001. **Acceptance:** both tops on the same base with identical anchors; POT on `pot_rest` without intersection; lit/embers/cold readable at size 16; culling of dome interior. Boundary: no chimney, no bread-oven brick look, no pottery kiln claim.

### ANIMAL-001 r001 — cattle and sheep (first livestock kit)

Evidence (S22/KY16): no animal bones survive at Březnice; regionally, Bohemian prehistoric farming relied on cattle, pig and sheep/goat, cattle usually dominant and sheep commoner than goats. Breed look, size, colour, horn form and herd size are R. This job supplies sheep, not goats. Chicken/cat exclusion is a project choice; local bone absence is not species-absence proof.

**Required files (2 GLBs + demo):** `models/cattle.glb` — small generic short-horned cow, withers 1.05–1.20 m, length ~1.8 m (R/design, deliberately smaller than modern breeds); `models/sheep.glb` — small short-tailed sheep, withers 0.55–0.65 m (R). Each ≤1800 (cattle) / ≤1200 (sheep) triangles, ≤2 materials, ≤1024² texture, ≤4 weights/vertex, ≤24 deforming bones, one shared quadruped bone-naming scheme documented (`root, pelvis, spine1-2, neck, head, jaw?, tail1-2, legs FL/FR/HL/HR ×3`). Origin at floor between hooves, +Z front.

**Clips (in place):** `idle` (2 s loop), `walk` (1 s loop, authoring speed 0.8 m/s documented), `graze` (2 s loop, head down), `lie_down` (~2 s), `lie_idle` (2 s loop), `stand_up` (~2 s). **Anchors:** `head_lead` (attachment) and static `base_center` at ground origin. Each three-bone leg chain includes its distal foot bone; document FL/FR/HL/HR names and four hoof-contact markers following those feet. Keep the model root fixed in every clip, including lying transitions. **Acceptance:** measure minimum Y of actual skinned hoof/foot vertices over every clip with between-key samples (≥-1mm), not just joint/marker heights; report planted-foot sliding as well. Animated contact markers help reproduce the measurement but do not replace mesh checks. Show loops in Godot, herd demo of 4 cattle + 8 sheep with actual PERSON for scale and a FENCE-001 pen if available, normal/close isometric views, culling check. Boundary: no yoke, cart, plough, milking scene, saddle or horse in this job; colours restrained and plural (no single "breed" livery).

### FENCE-001 r001 — wattle hurdle kit and small pen

Evidence: none for Březnice fences (R throughout). Woven wattle is a regionally attested wall technique (K22, comparators) and the authors infer regulated grazing in enclosures (S22). SF05 is a modern West Serbian stake-and-weave fence for construction logic only.

**Required files (4 GLBs):** `models/hurdle_2m.glb` — straight section 2.0 m long, 0.9–1.1 m high, pointed stakes at ~0.3–0.4 m, woven withy band(s); `models/hurdle_gate.glb` — 1.0 m lashed hurdle that reads as movable; `models/post_end.glb`; `models/pen_demo.glb` (demo-only assembly, ~5×4 m, not a production asset). ≤400 triangles per section (≤150 post), ≤2 materials, ≤1024² atlas; opaque geometry preferred, MASK cards listed if used for withies. **Anchors:** `snap_a`, `snap_b` at section ends (y0), `base_center`; gate has `hinge` node. **Acceptance:** 12-section chain with consistent snapping, overlap ≤10 mm; readability vs. HOUSE and grass at size 25; animals/person scale demo. Boundary: no sawn planks, nails or iron fittings; no claim of a mapped Březnice enclosure.

### LONGPIT-001 r001 — long pit with burnt deposit

Evidence (K22/C19/Z22): N–S trenches, typically 0.8–1 m wide, 3–7 m long, ~0.5 m deep (preserved 0.3 m in 1/05 and 12/06), one-step fill dominated by secondarily burnt coarse pottery, daub, clay pyramidal weights and stones; burning happened elsewhere. Interpretation as house-closing ritual is the authors' R.

**Required files (3 GLBs):** `models/longpit_open.glb` — 6.0×0.9 m (design, within E range) trench, 0.5 m deep, rounded ends/bowl walls, spoil heap along one side; `models/longpit_filling.glb` — partly filled with dark fill and readable sherd/daub/weight clusters (instanced fragments ≤20 unique); `models/longpit_closed.glb` — slightly sunken dark soil mark. ≤900 triangles each, ≤2 materials, ≤1024² atlas. Long axis along Z (= north in game convention, manager to confirm). **Anchors:** `base_center`, `deposit_point` at mid-length, `worker_origin_{w,e}` on both long sides. **Acceptance:** three states at identical camera; pit interior culling; depth reads at size 16; PERSON fixture standing at both worker origins. Boundary: no fire in the pit, no human remains, no default house-burning; any learning text must present the ritual reading as an interpretation.

## 7. Open questions / sources not accessible

1. **Šálková et al. 2025 (Archaeological Prospection)** — publisher bot-challenged; JČU handle `20.500.14178/3512` timed out; [Research Square preprint](https://www.researchsquare.com/article/rs-2665597/latest.pdf) not opened. Storage statements rely on opus-v2 notes.
2. **Chvojka et al. 2021**, *Rituály ukončení a obnovy* (monograph; ISBNs in Z22) — full feature catalogue, storage-jar drawings (incl. the three nested jars), kiln descriptions. Highest-value next read for STORE/KILN profiles and dimensions.
3. **Chvojka et al. 2009**, Březnice flat cemetery (*Archeologické výzkumy v jižních Čechách* 22:61–98) — not located online.
4. **Kuna et al. 2021**, J. Archaeol. Sci. 126:105298 (closed) and its [Data in Brief companion](https://doi.org/10.1016/j.dib.2021.106793) (gold OA, not read) — magnetometry anomaly classes might indicate pits/hearths/enclosures.
5. LBA South Bohemian hillforts, wells, fences: no source verified. Ask Chvojka/JU Institute of Archaeology for a short reading list.
6. Z22 Access DB and pottery tables not analysed beyond `_objekty`; `area_vykop` is excavated area, not necessarily whole-feature area.
7. Analyst classification differences in Z22 (`druh_MK` vs `druh_OCh`) for "pec" features — needs specialist adjudication.
8. HOUSE r001 design footprint (3.6×3.0m =10.8m²) versus K22’s assumed regional width5–8m: fit/design question only, no local footprint or house-length measurement established. Existing village geometry is unchanged.

## 8. Bibliography

- Chvojka, O., Menšík, P., Šálková, T., Kuna, M. 2019. Tkalcovská závaží nebo podstavce pod rožně? Archeologické rozhledy 71(2):267–308. https://doi.org/10.35686/ar.2019.11
- Chvojka, O., Kuna, M., Menšík, P. et al. 2021. Rituály ukončení a obnovy. Sídliště mladší doby bronzové v Březnici u Bechyně. České Budějovice–Praha–Plzeň. (not inspected)
- Chvojka, O., Kuna, M. et al. 2022. Sídliště z mladší doby bronzové v Březnici (Česko): data pro depoziční analýzu [dataset]. Zenodo. https://doi.org/10.5281/zenodo.6475797 (CC BY 4.0)
- Chvojka, O., Šálková, T., Beneš, J., Kovačiková, L., Novák, J. 2009. Březnice – první ploché pohřebiště mladší doby bronzové na Bechyňsku. Archeologické výzkumy v jižních Čechách 22:61–98. (not inspected; cited via S22)
- Kuna, M., Němcová, A., Šálková, T., Menšík, P., Chvojka, O. 2022. Deposition analysis and the hidden life of Bronze Age houses. Journal of Anthropological Archaeology 67:101433. https://doi.org/10.1016/j.jaa.2022.101433 (CC BY-NC-ND 4.0)
- Kuna, M., Křivánek, R., Chvojka, O., Šálková, T. 2021. A quantitative approach to magnetometer survey data: the case of the Late Bronze Age site of Březnice. Journal of Archaeological Science 126:105298. https://doi.org/10.1016/j.jas.2020.105298 (closed; not inspected)
- Kyselý, R. 2016. Historie chovu domácích zvířat v Čechách a na Moravě ve světle archeozoologických nálezů. Živa 2016(5):225–229. https://ziva.avcr.cz/2016-5/historie-chovu-domacich-zvirat-v-cechach-a-na-morave-ve-svetle-archeozoologickych-nalezu.html
- Šálková, T. et al. 2022. Extensive archaeobotanical data estimate carrying capacity, duration, and land use of the Late Bronze Age settlement site Březnice (Czech Republic). Scientific Reports 12:20323. https://doi.org/10.1038/s41598-022-24753-x (CC BY 4.0)
- Šálková, T. et al. 2025. Waste Management and Waste Disposal Detected by Combination of Analytical Methods: Late Bronze Age Březnice Settlement Site (South Bohemia). Archaeological Prospection 32:525–548. https://doi.org/10.1002/arp.1973 (CC BY; not re-inspected)
- Wikimedia Commons files as listed in §4 and `references/SFregistry.json`.
