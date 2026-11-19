# Economy research A — subsistence and household production chains

2026-11-06. Research proposal for the "Bronze Age Village" economy milestone. **Not historical approval, not a ticket assignment, not code.** Setting as in [`prototype-brief.md`](../prototype-brief.md): imagined household cluster inspired by Březnice near Bechyně (Tábor district), Ha A2–B1, c. 1150–1000 BCE, Knovíz / South-Bohemian Urnfield context.

Labels: **E** = bounded observation from an inspected, identified source, with page or section; **R** = inference, reconstruction, analogy or game-design choice; **F** = fiction. A regional or experimental comparator is never Březnice evidence: it is tagged *(regional: place, period)* or *(experiment: place, year)* and anything derived from it is R. A missing observation is not evidence of absence.

Sibling document: another agent is writing a parallel economy research doc in this folder. This document covers **subsistence**: arable cycle, crop processing, storage, diet, wild foods, animals, water, fuel/woodland, labour and demography.

---

## 1. Scope, method and sources actually read

### 1.1 Scope and method

1. Read the current economy code and tasks: `scripts/village_production.gd`, `village_simulation.gd`, `village_economy.gd` constants, `village_transport.gd` constants, BV-029, BV-030, BV-031, BV-032, BV-033, DEVELOPMENT_PLAN.md and the README economy sections.
2. Read the existing research: `content/research/next-batch/{README,settlement-features}.md`, `prototype-brief.md`, and `art/handoffs/bronze-bohemia-opus-v2/references/{SOURCES,research-notes}.md`.
3. Downloaded the local sources and extracted their text with `pypdf`. Scratch copies are kept outside the repo. Every page number below was checked against the extracted page.
4. Ran targeted OpenAlex queries (`filter=open_access.is_oa:true`) for Czech/Central European archaeobotany, millet, fodder, grinding experiments, crop-yield experiments and residues. Five additional open-access sources were read.
5. Every game number in §4–§5 is **R** and comes with its derivation. Where no source gave a number (fuel per day, spoilage rate, herd size, labour hours for tillage or harvest), **none is invented**. The parameter is left as an explicit tunable design value.

### 1.2 Sources read (access status)

| Key | Source | Access in this session | Licence / reuse | Use here |
|---|---|---|---|---|
| **S22** | Šálková T. et al. 2022, *Sci Rep* 12:20323 | Full PDF from the University of West Bohemia repository, pp. 1–16, all text incl. Tables 1–2. Figures not visually inspected. | CC BY 4.0 (p. 16; third-party credit exceptions) | Model assumptions, crops, charcoal, landscape, carrying capacity |
| **SP23** | Šálková T. et al., Research Square preprint rs-2665597/v1 (posted 14 Mar 2023), the preprint of **S25** | Full PDF, 28 pp. | CC BY 4.0 (preprint p. 2) | Crop proportions, starch/phytoliths, protein tests, storage contents. **Preprint: the published S25 text may differ.** |
| S25 | Šálková T. et al. 2025, *Archaeological Prospection* 32:525–548, doi 10.1002/arp.1973 | **Not accessible this session.** The Wiley host is blocked for web_fetch, and curl returned an HTML challenge. Repository handle 20.500.14178/3512 timed out. | CC BY (OpenAlex) | Cited only via SP23 and earlier project notes |
| **K22** | Kuna M. et al. 2022, *J. Anthropol. Archaeol.* 67:101433 | Full PDF from the same repository, 16 pp. | **CC BY-NC-ND**: cite and link only, nothing copied | Storage vessels, house life, boiled-meat residue mention, storage-pit hypothesis |
| **C19** | Chvojka O., Menšík P., Šálková T., Kuna M. 2019, *Archeologické rozhledy* 71:267–308 | Full institute PDF, 42 pp. (journal p. = PDF p. + 266) | Journal; cite only | Plant impressions in clay weights: crops, chaff, acorn, hazel, sloe |
| **KY16** | Kyselý R. 2016, *Živa* 2016/5:225–229 | Full PDF, 5 pp. | Academia: reprint forbidden; cite only | Regional animal husbandry, secondary products |
| **AR24** | Pokorná A., Kočár P., Šálková T. 2024, *Archeologické rozhledy* 76:173–188 | Full PDF, 16 pp. | Open access (journal); cite | Czech Bronze Age crop and gathered-plant trends, sowing seasons |
| **H15** | Hejcman M., Hejcmanová P. 2015, *IANSA* VI/1:31–45 | Full PDF, 16 pp. (journal p. = PDF p. + 30) | CC BY (OpenAlex) | Czech field experiment: emmer yield, seed rate, dehusking ratio, straw value |
| **B20** | Bofill M. et al. 2020, *J. Lithic Studies* 7(3) | Full PDF, 26 pp. | CC BY 4.0 (p. 1) | Experimental grinding rates (Greek experiments) |
| **O24** | Orfanou E. et al. 2024, *Sci Rep* 14:4382 | Full PDF, 13 pp.; abstract and introduction read | CC BY 4.0 | Millet growing period; LBA millet consumption in central Germany |
| BR24 | Breu A. et al. 2024, *PLOS ONE* 19(5):e0301278 | Abstract read only | CC BY | Low relevance: lipids in central Germany, mostly pre-LBA. Not used for claims. |
| Z22 | Zenodo 10.5281/zenodo.6475797 (Březnice deposition data) | **Blocked this session** (Zenodo 403 "unusual traffic") | Dataset licence per record | Only the counts already verified in `next-batch/README.md` are reused, labelled as inherited |

Not obtained (cited inside S22 for its model inputs; see §6): Neustupný 1986 (*Památky archeologické* 77), Dreslerová 1996 (*AR* 48), Danielisová 2008/2010 (České Lhotice oppidum, Iron Age), Jacomet & Karg 1996 (Zug-Sumpf, Swiss lake-dwelling LBA), Karg 1998 (Fiavè, N Italy).

---

## 2. Findings per topic

### 2.1 The Šálková 2022 carrying-capacity model: every quantitative assumption

S22 combines catchment analysis (SCA) with demand per household. **All demand inputs are borrowed from other studies, regions and periods. They are model assumptions, not Březnice measurements.** In the table, "E (model input)" means S22 reports that it used this value. The value itself is R/comparator.

| # | Quantity | Value | Where in S22 | Original basis named by S22 | Label |
|---|---|---|---|---|---|
| M1 | Houses built over the whole occupation | 70 (one per long pit / trench) | p. 5 "Site and region"; p. 10 | ~70 trenches from magnetometry, 21 excavated (p. 3) | E (count of features) + R (1 trench = 1 house) |
| M2 | House lifetime | ~25 years | p. 5 | refs 3, 59 (Neustupný 1986; Chisholm 1979) | E (model input) / R |
| M3 | Field cultivated per family per year | 1–3 ha | p. 5 | Neustupný 1986 | E (model input) / R |
| M4 | Grain yield | 600–800 kg/ha/yr | p. 5 | ref 63, Jacomet & Karg 1996 *(regional: Zug-Sumpf, Switzerland, LBA lake dwelling)* | E (model input) / R |
| M5 | Grain consumption | ~200 kg per person per year | p. 5 | ref 60, Danielisová *(regional: České Lhotice, Iron Age)* | E (model input) / R |
| M6 | Fallow area relative to cultivated area | 4–6× | p. 5 | ref 7, Dreslerová 1996 | E (model input) / R |
| M7 | Total field system per house | "562 to 7.5 hectares" in the PDF text. This is garbled; Table 2 and p. 10 use **5 ha** (intensive) and **7.5 ha** (optimal) per house. | p. 5; p. 10; Table 2 p. 11 | refs 60, 61 | E (model input) / R |
| M8 | Grazing per family's animals | ~6.25 ha | p. 5 | refs 60, 61 (Danielisová, Iron Age) | E (model input) / R |
| M9 | "Cultural forest" per family (firewood, construction wood, food, forest pasture) | ~125 ha | p. 5 | ref 7 (Dreslerová 1996) | E (model input) / R |
| M10 | People per house | **5** (implied: Table 2 "people at one moment" ÷ "houses at the same time" = 5.0 in every row, e.g. 33.14 / 6.63) | Table 2, p. 11 | not stated in text | E (implied model input) / R |
| M11 | Catchment limit | ≤ 1 h walk (~3.5–4.5 km) | p. 5 | 1 h to the Lužnice canyon boundary | E (model input) |
| M12 | Field radius | 15 min walk ≈ **1,100 m**; zone of strongest impact 500 m from households | p. 5 | refs 7, 80, 82 | E (model input) |
| M13 | Pasture zone / cultural forest zone | ≤ 30 min / ≤ 60 min walk | p. 5 | refs 82, 22 | E (model input) |
| M14 | Modelled field land available | optimum **69 ha**, maximum **104 ha** (~1% of the settlement area) | Results p. 7; Table 1 p. 7 | prediction model | E (model output) |
| M15 | Modelled pasture / forest availability | pastures 1,566 ha; woodland 50 ha (≤15 min), 337 ha (15–30 min), 5,704 ha (30–60 min) | Table 1 p. 7 | SCA + 19th-century maps | E (model output) |
| M16 | Limiting factor | Forest and pasture **not** limiting; field land **is** limiting | p. 10; p. 12 | — | E (authors' model conclusion) |
| M17 | Simultaneous households and duration | max ~20 houses for ~90 years (max fields, intensive use); ~14 houses for ~126 years (extensive); ~9 houses for ~192 years (optimal) | pp. 10–12, Table 2, Conclusion p. 13 | — | E (model output) |
| M18 | Population at one moment (Table 2 rows) | 33–120 people across durations of 264–73 years (e.g. 45.6 people at 192 years; 100 people at 87.5 years) | Table 2 p. 11 | — | E (model output) |
| M19 | Occupation span | 14C: 73–264 yr (95%), 107–192 yr (68%); typology 100–150 yr | p. 3; p. 10 | OxCal on 15 samples | E |
| M20 | Fields location | Probably E and N of the site, 10–15 min walk; drier fields E/N, wetter fields N/NE close by | p. 8 "Fields" | SCA + weed ecology | R (authors' model) |

**Consistency check (R, my arithmetic):** 5 people × 200 kg = 1,000 kg/yr per house. At 600–800 kg/ha this needs **1.25–1.67 ha** harvested, before seed. That lies inside M3 (1–3 ha). With M6 fallow (4–6×), the total is 6.25–11.7 ha, in the same range as M7 (5–7.5 ha). The 5 ha "intensive" variant therefore implies a fallow ratio of only ~2–3×, or a smaller cultivated area. The paper does not state seed reserve, losses or animal feed in its grain budget.

### 2.2 Crops, sowing season and crop mix

- **E (S22 p. 6, Results):** charred crops at Březnice are *Panicum miliaceum* (broomcorn millet), *Hordeum vulgare* (barley), *Triticum dicoccum* (emmer), *T. monococcum* (einkorn), *T. spelta* (spelt), *T. aestivum/durum/turgidum* (free-threshing wheat), *Lens culinaris* (lentil), *Pisum sativum* (pea) and *Vicia faba* (faba bean). Assemblages contain grain, rachis internodes, glume bases and pulse seeds, i.e. both products and processing waste.
- **E (SP23 §3.1, preprint p. 7):** 35,238 charred macroremains; 47.56% are crops, of which 86.74% cereals and 13.26% legumes.
  - Among cereals, millet is 73% overall. Excluding two concentrated samples (features 1/07, 12/06): barley 31%, millet 19%, indeterminate 24%, wheats about a quarter (emmer 9%, spelt 4%, einkorn 4%, free-threshing 1%, others).
  - Barley occurs in 37 features and millet in 35.
  - Legumes, excluding the same concentrations: lentil 38%, *Pisum/Vicia* 33%, pea 15%, faba bean 12%. *Vicia ervilia* is under 1% overall.
  - **R:** charred-remain proportions reflect what got burnt and preserved, not field areas or diet shares.
- **E (SP23 §4.1, p. 11):** the authors read barley as the dominant crop if millet is set aside, because its small grains carry less food potential. Lentil is the most frequent legume.
- **E (SP23 §4.1, p. 11; authors' interpretation citing Tempír 1985, Miller et al. 2016, and Hajnalová 2012 for Slovakia):**
  - Millet and legumes were spring-sown.
  - Barley was probably spring-sown where growing seasons are short.
  - Wheat was "probably" winter-sown *(regional analogy: Slovakia)*.
  - "The basis of crop production in Březnice … was probably spring crops." A wide crop range let one failed crop be substituted by another.
- **E (AR24 p. 185):** millet and pulses are always spring-sown. Barley, emmer and einkorn can be spring or winter crops. Spelt is often a winter cereal. In the LBA, millet reached its maximum Representativeness Index (93) across Czech sites, with 95% ubiquity (p. 181, Tab. 3 p. 182). South Bohemian data contain "a high proportion of broomcorn millet, especially in LBA, in higher elevations" (p. 185). Crop diversification "probably also [allowed] better distribution of field work throughout the year" (abstract p. 173).
- **E (O24 pp. 1–2) *(regional: central Germany)*:** millet has a "short growing period (around three months in Central Europe)" and is "suitable for long-term storage". Isotopes show substantial millet consumption c. 1300–1050 BCE at Esperstedt/Kuckenburg (abstract p. 1).
- **E (C19 p. 286):** among identifiable grain impressions in the clay weights, barley 27% is dominant and millet 4.6% + 4% (*Panicum*/*Panicum-Setaria*). The authors note that small millet grains are hard to identify as impressions (p. 294). There are probable oat impressions (cf. *Avena*, 0.5%). Legume impressions: faba bean 35.3%, pea 23.5%, pea/vetch 35.3%, vetch/lentil 5.9%.
- **E (AR24 p. 181, Tab. 3 p. 182; SP23 §4.1 p. 11):** flax and poppy are rare or absent in LBA assemblages (AR24 records one poppy seed, at Hvožďany; SP23 says both are rare in South Bohemia).
- **R:** no oil/fibre-crop function should be prominent at Březnice.

### 2.3 Tillage, sowing, weeding, harvest (field operations)

- **E (S22 p. 3, citing Pavelka et al.):** an experiment with replica Bronze Age tools suggested that Bronze Age people ploughed previously deforested pasture areas.
- **E (KY16 p. 227) *(regional synthesis)*:** reliable evidence of animal traction in the Czech area dates from the end of the Eneolithic. Direct finds of real ploughs date from the start of the Bronze Age; wooden yokes are known in Europe from the second half of the 4th millennium BCE. Cattle provided "milk and draught power". **R:** an ard pulled by a cattle pair is a defensible regional reconstruction for Březnice, but it has no local evidence.
- **E (H15 p. 31 abstract; pp. 32–33 methods) *(experiment: Czech Republic, one season)*:**
  - A hoe was the easiest way to convert permanent grassland into arable land. A scratch plough or wooden spade worked only on existing arable land without dense sward.
  - Broadcast sowing worked. Seed left on the surface was eaten by rodents and birds, and spikelets were covered with rakes.
  - Emmer was sown on 24 April at the upper recommended rate of **400 germinable caryopses/m²**.
  - Harvest was by hand on 10 August. Note: the paper gives 2014 for sowing and 2013 for other dates (p. 33 vs pp. 35, 38). This is an internal inconsistency in the source.
- **E (H15 p. 38, Table 2 p. 37):**
  - No weeding was done in the prehistoric-technology plots.
  - The plots held 31 and 28 weed species, versus none in the modern field.
  - Emmer coped well with weeds.
  - Kernel weight (1,000 grains) was 25–30 g.
- **E (S22 p. 8):** weed seeds came into the settlement with the harvest. After cleaning they were deposited as waste or reused, e.g. as organic temper in ceramics or daub.
- **R (game):** weeding should be minor or optional. The Czech experiment shows no weeding still gave a harvest, while weeds were abundant at Březnice. Treat weeding as a summer "tend" activity whose absence lowers yield modestly. That effect size is a design choice, not a measured value.

### 2.4 Crop processing: threshing, winnowing, dehusking, parching

- **E (SP23 §3.1 p. 7):** among hulled wheats, **glume bases (waste) outnumber grains: 51% vs 34%** of wheat finds.
  - **R:** dehusking of hulled wheat took place on site, near the houses.
- **E (SP23 §3.9.1 p. 10):** feature groups differ: one group has hulled-wheat glume bases only, another hulled-wheat grains only.
  - **R:** processing stages and waste disposal were spatially separated (cleaning or dehusking in one place, storage or consumption in another).
- **E (C19 p. 283; p. 286; p. 295):**
  - Of 1,745 plant impressions on 99 clay weights, cereal products (grain) make up 57% and cereal waste (chaff, glumes, spikelets, straw) 38%.
  - Straw (Cerealia/Poaceae culms) is 71.2% of the indeterminable cereal impressions.
  - The authors consider crop-processing waste the main organic temper of the weights. Waste was collected for further production without selective sorting.
  - **R:** chaff and straw are a by-product with a use (clay temper, daub), which supports a by-product output in the game.
- **E (H15 p. 31, abstract) *(experiment)*:**
  - Emmer grain = **75% of spikelet weight**, so dehusking removes ~25% of the mass.
  - The nutritive value of glumes is low. The authors infer that clean grain was preferred and whole spikelets eaten mainly in shortage (p. 42).
- **E (B20 pp. 13, 20) *(experiment: Greece, PLANTCULT)*:**
  - Grinding hulled cereals took more effort and time than grinding dehusked grain, "especially in the case of barley".
  - Dehusked millet gave the highest flour output.
  - Coarse grinding into groats is faster than fine grinding (~0.8 kg/120 min) but needs sieving or winnowing afterwards.
- **Parching:** no Březnice source inspected here reports parching or kiln-drying. **R only.** Do not attach a grain-drying function to the coded *O-pec* burnt features (see `next-batch/README.md`): they are unresolved burnt surfaces.

### 2.5 Grinding and food preparation

- **E (SP23 §3.3–3.5 pp. 8–9; §4.1 p. 12):**
  - Grinding slabs carry starch of grasses (Poaceae), wheat (cf. *Triticum*), cf. einkorn, and the legume family (Fabaceae).
  - Some slabs have phytoliths of cereal husks, leafy or woody plant parts, fungal spores and brown ash.
  - Gliadin (cereal protein) was found on two slabs and in three features.
  - The authors relate the grinding slabs to food preparation of "material other than grain".
  - **R:** the saddle quern was multipurpose (cereals, legumes, possibly other plants), not barley-only.
- **E (B20 p. 12, p. 13, p. 14) *(experiment: Greece; saddle-quern-type tools)*:**

  | Material / tool | Output |
  |---|---|
  | Big tools, average | 1.09 kg per 120 min |
  | Small tools, average | 0.667 kg per 120 min |
  | Small tools, discussion average (p. 19) | "1.5 kg of ground product in 5 h" |
  | Dehusked millet, sandstone | 0.957 kg/120 min |
  | Dehusked millet, andesite | 1.3 kg/120 min |
  | Coarse groats | ~0.8 kg/120 min |
  | Acorns, roasted | 0.433 kg/120 min (maximum) |
  | Acorns, dried | 0.489 kg/120 min (maximum) |
  | Linseed / poppy, roasted | 0.588 / 0.775 kg/120 min |

  - **R derivation:** fine-grinding cereal yields ~0.33–0.55 kg/h; millet ~0.48–0.65 kg/h.
- **R (combining M5 and B20, my arithmetic):**
  - A 5-person house at 200 kg/person/yr needs ~2.7 kg grain per day (1,000/365).
  - Grinding all of it to flour at 0.33–0.55 kg/h takes **~5–8 person-hours every day**. For the game's 4-person house (2.2 kg/day) it is **~4–6.6 h/day**.
  - **Learning value:** if grain is eaten as flour, grinding is one of the largest single daily labour sinks.
  - Whole-grain boiling (millet porridge, pulses) or coarse groats reduce grinding demand. This is a strong reason to model several meal types.
- **E (K22 p. 10, §5.3.1, citing Pavelka 2021):** many samples from artefact surfaces and long-pit soil "provide evidence of boiled-meat proteins" and indicate cooking. (Cite only; NC-ND.)
- **E (SP23 §3.5 p. 9; §2.2 method p. 6):** the method is food-antibody tests, which detect proteins.

  | Protein target | Result reported |
  |---|---|
  | Cooked pork | positive in 13 of 18 samples |
  | Uncooked pork | absent in only two features |
  | Uncooked poultry | 6 of 19 samples, incl. grinding slab 2/09, "roasters" from 1, 5, 6/07 and a bowl |
  | Cooked poultry | all 14 samples |
  | Beef | all 10 samples |
  | Casein (milk) | tested in 21 samples; positive in fills of features 2, 8, 13, 19–20/19 and on the surface of bowl 8/19 |
  | Ovomucoid (egg) | not detected in any of 3 samples |

  - **R/caution:**
    - These are immunological detections in the preprint, and the published S25 should be checked.
    - "Poultry" is the test category and may not mean domestic chicken. The project's current chicken exclusion should be re-reviewed against S25 rather than silently changed.
    - The sentence "Casein … observed in 21 samples" is ambiguous; it reads as "tested in 21".
- **R (game diet):**
  - Porridge or stew of millet, groats or pulses.
  - Flour-based flatbread or dough. This is generic: no bread oven is evidenced here, and the *O-pec* features are unresolved.
  - Boiled meat at intervals.
  - Milk / dairy.
  - Gathered foods.
  - Recipes and proportions are **F/R**.

### 2.6 Storage and losses

- **E (K22 p. 4 §3.2; p. 8 §5.2):**
  - Excavated features include sunken storage vessels and a storage pit.
  - Five features are interpreted as **sunken storage vessels, probably inside houses or under a roof**. Four lie ~**2.5 m west of long pits**, possibly roughly mid-house.
  - Fig. 3 caption: feature 6/05 is "interpreted as storage pit, originally with a sunken vessel".
- **E (K22 p. 10 §5.3.1):** in one feature there are three storage jars "inserted into each other". The authors read this as gradual renewal or replacement of a sunken storage jar over several years.
- **E (K22 p. 13 §6, hypothesis):** LBA settlements in Bohemia have the highest numbers of sunken features, mostly storage pits. The authors suggest these may reflect, e.g., **"digging a new storage pit for each household every year"** as an annual agricultural-cycle ritual. This is explicitly a hypothesis.
- **E (SP23 §4.2 p. 12):** "The life of the (storage) pits was not long (Neustupný 1986) and after the loss of their primary function they were filled with waste."
- **E (SP23 §4.2 p. 13):**
  - "The storage pits/vessels did not contain any remains of stored crops."
  - A concentrated find of *Chenopodium album* seeds in vessel 11/06 is mirrored in nearby stake pit 6/06. This is either on-site sedimentation or deliberate seed deposition.
- **E (inherited, Z22 via `next-batch/README.md`):** among 449 typed pottery individuals there are 146 storage jars. Five Zenodo records use `O-zásobnice`. *Not re-verified this session.*
- **E (O24 p. 2) *(general agronomic statement, regional paper)*:** millet is suitable for long-term storage.
- **Spoilage and loss rates:** no source inspected gives a number. **R only.**
- **R (game):**
  - Household sunken jars inside or near the house hold food grain (STORE-001).
  - A pit can be dug as a seasonal event. Do not show a filled pit's contents as evidence; label as R.
  - Seed grain kept separate from food grain (R design).
  - Losses come from pests and damp, set by a designer-chosen rate, and are visible.

### 2.7 Gathered wild foods

- **E (C19 p. 283):** impressions of potentially gathered plants are 4% of all identified impressions.
- **E (C19 p. 286):** of gathered-plant impressions:

  | Item | Share |
  |---|---|
  | Grass grains (Poaceae) | 50% |
  | Grass leaves | 7.1% |
  | **Acorns** (*Quercus* sp., cf. *Quercus*) | **26.2%** |
  | **Hazelnuts** (cf. *Corylus avellana*) | **7.1%** |
  | Vetch (*Vicia* sp.) | 7.1% |
  | Polygonaceae | 1.2% |
  | **Sloe** (cf. *Prunus spinosa*) | **1.2%** |

- **E (C19 p. 288, DCA summary):** acorn impressions co-occur with barley and emmer impressions; hazelnut and sloe-stone impressions co-occur.
- **E (C19 p. 295):**
  - Acorns were **not found charred** in the feature fills (citing Šálková 2010).
  - The authors suggest they were not processed with fire on site, and served **either as animal fodder or were ground to flour before heat processing**.
  - Either way, acorn impressions capture resource acquisition "from the forest" in the hinterland. (Authors' interpretation.)
- **E (SP23 §4.1 p. 12):**
  - Wild plants were gathered across the settlement area.
  - Seeds of potential leafy vegetables are present: *Chenopodium album*, *Alliaria petiolata*, *Atriplex*, *Thlaspi arvense*, *Rumex*.
  - Fruits are present: sloe, elder, *Solanum nigrum*, raspberry, blackberry.
  - "Hoard" finds of *Fallopia convolvulus* (12/06) and *Chenopodium album* suggest harvesting of wild seeds.
  - (Authors' interpretations: these could be weeds of crops.)
- **E (AR24 p. 181):** in Czech LBA sites, hazelnut, wild strawberry, blackthorn (sloe), rose, blackberry and elderberry appear in many sites "but only in small quantities". At one EBA site the authors suggest gathering *may* have compensated for poor harvest, but "the uniqueness of the case does not allow us to draw general conclusions" (p. 184).
- **R (game):** gathering is a minor, seasonal supplement and a shortage buffer, not a staple.
  - Late summer: berries, sloe after frost.
  - Autumn: hazelnut, acorn.
  - Spring/summer: wild greens.
  - Acorn processing (dry → shell → grind, or feed to pigs) is a defensible R activity, with B20 rates as experimental anchor.

### 2.8 Animal husbandry

- **E (S22 p. 12; SP23 §4.1 p. 12):** animal bones do not survive at Březnice because of acidic soil. Regional animal species are known from KY16.
- **E (SP23 §3.5):** beef, pork and "poultry" proteins and casein were detected (see §2.5). This is the **only local evidence of livestock products**. **E (SP23 abstract):** "Animal proteins detected the presence of livestock meat and dung."
- **E (KY16 p. 227) *(regional: Bohemia/Moravia)*:**
  - Farming communities were always based on cattle, pig and sheep/goat.
  - Cattle is usually dominant in prehistoric bone assemblages and provided milk and draught power.
  - Sheep/goat usually rank third, with sheep commoner than goats.
  - Sheep give meat, milk and wool, and their grazing reshaped the landscape.
  - Spinnable wool appears in Europe from the start of the 3rd millennium BCE.
- **E (S22 p. 3; p. 9):**
  - Forest and cleared areas served as pasture.
  - Forests could provide fodder and litter in winter, "when the dried branches with leaves were used for feeding" (citing Karg 1998 *(regional: Fiavè, N Italy, Bronze Age)* and Buček 2000).
  - Grazing took place "in the enclosures and in the forests, which were made more open".
  - Grazing "had to be regulated" to avoid crop damage.
  - "Winter fodder for animals had to be obtained within the reach of the settlement area."
  - Animals grazed on ruderals, slopes and stream meadows (Conclusion p. 12).
- **E (S22 p. 9):** grazing increased soil fertility, reduced weeds and prevented forest regrowth (authors citing ref 95).
- **E (H15 p. 31, p. 42) *(experiment)*:** emmer straw has too little N and P for optimum cattle nutrition. Straw was probably fodder "only if better forage was not available".
- **E (S22 p. 9):** wet meadows and pastures existed (wetter grassland taxa list).
  - **R:** hay from floodplain meadows is plausible. **Unverified here:** hay-cutting tools. Do not show long scythes.
- **Herd size, milk yield, slaughter age, lambing/calving season:** no number in inspected sources. **R/F.** M8 (6.25 ha grazing per family) is the only quantity, and it comes from an Iron Age comparator.

### 2.9 Fuel, wood and woodland management

- **E (S22 pp. 6–7, Fig. 5):**
  - Charcoal taxa: *Abies, Alnus, Betula, Corylus, Fagus, Fraxinus, Quercus, Picea, Pinus, Populus/Salix, Tilia*.
  - *Quercus* is dominant.
  - Light-demanding, early-succession trees are frequent (*Pinus, Betula, Corylus, Populus/Salix*).
  - Late-succession trees are lower.
  - Březnice has more pioneer trees and light shrubs than Hvožďany.
  - Average 2.75 charcoal taxa per sample.
- **E (S22 p. 10):**
  - Oak was "mainly used as a construction material".
  - Fir was construction wood, mostly in stake pits.
  - "The material commonly available in the forests surrounding the settlement area served as firewood."
- **E (SP23 §3.2 p. 8):** *Quercus* occurs in 82.9% of charcoal samples, *Pinus* 48.6%, *Betula* 31.4%, *Abies* 27.1%, *Fagus* 24.3%, *Populus/Salix* 22.9%, *Picea* 15.7%, *Tilia* 10%, *Corylus* 7.1%, *Alnus* 2.9%.
  - **R:** the fills mix house-destruction charcoal and hearth waste. Do not read these as fuel proportions.
- **E (S22 p. 10):**
  - The immediate vicinity was "probably forestless".
  - Forests within ~30 min were "significantly influenced by human activity".
  - Influence decreased with distance.
  - Modelled woodland is only 50 ha within 15 min (Table 1). The authors still judge forest not limiting (p. 10), because 5,704 ha lie within 30–60 min.
- **E (K22 p. 6 §4, Klouzková 2021 cited):** secondary fire on finds reached 1,000–1,200 °C. **R:** house-burning or closing events consumed large amounts of wood. That is a **ritual/deposition** topic (sibling scope), not a routine fuel demand.
- **Fuel quantity per hearth-day or per firing:** not found in inspected sources. **R only.** M9 (125 ha cultural forest per family) is an area including pasture and food, not a fuel rate.
- **R (game):**
  - Firewood from nearby deadwood, pioneer scrub (birch, hazel, pine, poplar) and lopped branches.
  - Larger oak trees go to construction.
  - Distance to wood grows as the near zone is depleted. This supports S22's "forestless vicinity" and gives visible landscape change.

### 2.10 Water beyond drinking

- **E (S22 p. 3):** the site is on a hill (455 m asl) above the Židova strouha and Blatecký potok streams, in relatively deep valleys.
- **E (S22 p. 10):** wet woodland and stream-edge habitats are "within a quarter-hour walk".
- No inspected source gives water use for animals or cooking, or an ancient water point.
- **R (game):**
  - Animals are watered at the stream during herding, not by carried water. This keeps hauling realistic in scale (avoid dozens of pot trips).
  - Cooking consumes a small amount of household water per cooking batch. This links the existing water deliveries to actual consumption, which BV-029 deferred.

### 2.11 Labour, demography and household

- **E (S22 Table 2 p. 11):** 5 people per house (implied model assumption, M10).
- **E (K22 p. 10 §5.3.2):** house lifetime is estimated at one generation (20–25 years), from general models rather than local data.
- **E (K22 p. 8):** long pits 2–6 m apart are likely asynchronous; pairs ~10 m apart may be houses standing side by side.
- **E (SP23 abstract; §4.2):** feature fills reflect "specific economy and habitats around the single households". Waste of successive households on the same spot mixed.
- **E (S22 p. 12):** Březnice and Hvožďany were each self-sufficient in plant production (product and waste both present).
- **R:** a household is the main unit for crop processing, storage and cooking; community-level work is a design option. BV-032 already states the household-first choice as a simulation choice.
- **Age and sex labour division, child labour, elders:** nothing inspected. **R/F.** The prototype brief already says not to assert fixed gender or age roles.
- **Climate (E, S22 p. 3):**
  - Modern lower Lužnice microregion: 7.0–7.5 °C mean annual temperature, ≤ 600 mm precipitation, one of the warmest areas of South Bohemia but below-average humidity.
  - LBA South Bohemia: "rather stable and dry" (refs 47–48), with flood deposits 1200–1000 BC in peat cores.
  - **R:** an occasional dry or poor year is plausible as a scarcity driver, without implying famine or deaths.

---

## 3. Economic process map (subsistence scope)

Notation: `[E]`, `[R]`, `[F]` per element. "HH" = household, "C" = community/shared.

### 3.1 Resources

| Resource | Where (game) | Evidence |
|---|---|---|
| Arable plots: barley, millet, pulses (spring); wheats (spring or winter) | FIELD east/north, ≤ ~1 km (15 min) | crops [E S22 p. 6]; sowing season [E AR24 p. 185, SP23 §4.1 = authors' interpretation]; location [R S22 model p. 8]; plot sizes/mix [R] |
| Fallow / dry pasture | between field and woodland | [E S22 abstract and p. 9 habitats]; extent [R model] |
| Wet meadow (floodplain) | toward WATER | [E S22 p. 9 taxa list]; hay use [R] |
| Woodland: oak, hazel, birch, pine, fir | ≤ 30–60 min | [E S22 pp. 6–7 charcoal]; use split [E S22 p. 10 authors' interpretation] |
| Wild foods: hazelnut, acorn, sloe, berries, greens, wild seeds | scrub/woodland edge, ruderal | [E C19 p. 286, AR24 p. 181, SP23 §4.1]; quantities [R] |
| Livestock: cattle, sheep (+ pig regionally) | pasture/enclosure | [E SP23 proteins; KY16 regional]; herd size [F/R] |
| Water | stream below hill | [E S22 p. 3]; collection point [R] |

### 3.2 Transformations

| Step | Input → output | Who | Tools/facility | Labour | Evidence |
|---|---|---|---|---|---|
| Tillage | fallow/pasture → seedbed | HH (C for ard team?) | hoe/spade; ard + cattle pair | high, spring (and autumn for winter crop) | hoe/ard [E H15 experiment; KY16 regional]; on-site [R] |
| Sowing | seed grain → sown plot | HH | broadcast + rake | moderate | [E H15 experiment]; seed reserve [R] |
| Tending/weeding | — | HH | hand | low/optional | weeds abundant [E S22 p. 8, H15]; benefit [R] |
| Harvest | ripe crop → sheaves/ears + straw | HH (C peak) | sickle *(not verified here)* | peak in late summer | timing [E H15 experiment 10 Aug; O24 ~3-month millet]; tool [R] |
| Threshing/winnowing | sheaves → grain/spikelets + chaff + straw + weed seeds | HH | floor, beating, wind | moderate, after harvest | waste present [E SP23 §3.1; S22 p. 8]; method [R] |
| Dehusking (hulled wheat, barley, millet) | spikelets → clean grain (≈ 0.75 by weight) + glumes | HH | pounding/quern | moderate | glume bases on site [E SP23]; ratio [E H15 experiment] |
| Grinding | clean grain → flour/groats | HH | saddle quern (WORK) | **high daily** | quern & residues [E SP23 §3.3–3.5, SOURCES B/C]; rate [E B20 experiment] |
| Cooking | flour/groats/pulses/millet + water + fuel → meals | HH | hearth, pots | daily | boiled meat [E K22 p. 10]; dishes [R/F] |
| Storage | grain → sunken jar / pit | HH | storage jar, pit | dig: seasonal | features [E K22 p. 8]; contents [not evidenced: E SP23 §4.2] |
| Gathering | wild plants → nuts, fruit, greens, acorns | HH/individual | baskets *(R)* | seasonal | [E C19, SP23, AR24] |
| Acorn processing | acorns → fodder or flour | HH | drying, quern | moderate | [E C19 p. 295 authors' alternatives; B20 rates experiment] |
| Herding | animals ↔ pasture | HH or C rotation | enclosure | daily (non-winter) | [E S22 p. 9 interpretation]; rota [R] |
| Leaf fodder/hay | branches/grass → winter fodder | HH | lopping, drying | summer peak | [E S22 p. 3, p. 9, regional citation]; method [R] |
| Winter stalling | fodder → maintained animals + dung | HH | house/byre? | daily (winter) | stalling location [R]; dung [E SP23 abstract] |
| Milking, slaughter | animals → milk, meat, hide | HH | pots | seasonal/occasional | casein, meat proteins [E SP23]; scheduling [R] |
| Manuring | dung → field fertility | HH | carrying | low | [R]; S22 grazing → fertility [E authors] |
| Firewood | woodland → fuel | HH | axe *(regional, not verified here)* | year-round, more pre-winter | [E S22 p. 10]; rate [R] |
| By-product reuse | chaff/straw → clay temper, daub, fodder, bedding | HH | — | low | temper [E C19 p. 295; S22 p. 8]; fodder [E H15 low value] |

### 3.3 Seasonal calendar (R synthesis for the 4-season game clock)

The game has Spring / Summer / Autumn / Winter (`village_calendar.gd`), and production currently treats season 3 as "fallow". Evidence anchors: spring sowing of millet, pulses and barley [E AR24, SP23 interpretation]; possible autumn-sown wheat [E SP23, regional]; emmer sown late April and harvested ~10 August [E H15 experiment]; millet ~3-month season [E O24].

| Season | Arable | Processing/food | Animals | Woodland/gathering |
|---|---|---|---|---|
| Spring | tillage; sow barley, millet, pulses (and spring wheat) from **seed stock** | grind/cook from stores; stores lowest → shortfall risk | out to pasture; milk begins *(R)* | wild greens *(R)* |
| Summer | tend/weed; **harvest of winter wheat/barley late summer** *(R from H15 date)* | threshing, winnowing begin | herding; **cut leaf fodder & hay** | berries; firewood stockpiling *(R)* |
| Autumn | harvest millet & pulses; threshing; **sow winter wheat**; dig/renew storage pit *(K22 hypothesis)* | dehusking, filling jars, **seed set-aside** | slaughter of surplus animals *(R)* | **hazelnuts, acorns, sloes** |
| Winter | fields fallow | grinding and cooking from stores; craft (sibling scope) | stalled/fed fodder; dung accumulates | firewood cutting *(R)* |

**Mismatch with current code (R):** BV-029 harvests in autumn and tends in summer, after a single spring sowing. That is acceptable for millet and pulses, but cereal harvest usually starts in **summer**. A multi-crop version should split harvest across late summer (cereals) and autumn (millet/pulses).

### 3.4 Storage and spoilage

- **Seed stock:** separate and protected; consumed in spring (and autumn for winter wheat). [R]
- **Food stock:** sunken jar in the house, plus pit when dug. Contents are not archaeologically demonstrated [E SP23 §4.2].
- **Losses:** a small periodic loss from pests and damp, higher in pits than jars. [R; no rate in sources]
- **Winter shortfall:** stocks fall from autumn to the next harvest. The lean season is late spring and early summer [R]. This fits the existing capped unmet-need counter without deaths.

---

## 4. Candidate simulation functions

Common conventions (R):

- "**unit**" means the existing abstract grain unit. Under BV-029, a 4-person house eats 4 portions/day × 120 days/year = 480 portions = **10 flour units/year**, matching `HARVEST_SHARE = 10`. So **1 unit ≈ one-tenth of a 4-person household's annual cereal food**.
- With S22's 200 kg/person/yr, 1 unit corresponds to ~80 kg grain-equivalent. This is a scale explanation only, never displayed as a measured quantity.
- The game year has 120 days, so one game day ≈ 3 real days of consumption.
- No coins, prices, markets, wages or "profit". Transfers between households, if any, are sibling scope and should be framed as sharing/obligation, not sale.

### F1. Multi-crop plots and a two-sowing calendar

- **Visible:** villagers sow distinct patches in spring (barley, millet, pulses) and one patch in autumn (wheat). Patches ripen at different times.
- **Inputs → outputs:** seed units + labour → sown plot → crop units at harvest.
- **R parameters:**
  - `CROPS = {barley, millet, pulse, wheat}`.
  - Plot share per household, e.g. barley 4, millet 3, pulse 2, wheat 1 of 10 crop units. This loosely echoes SP23's non-concentrated proportions (barley > millet > wheats, legumes ≈ 13% of crops), but **is not a field-area claim**.
  - Ripening: millet/pulses one season after sowing [O24 ~3 months]; barley/wheat harvested late summer.
- **Season:** spring and autumn sowing; summer and autumn harvest.
- **Scope:** household plots, adjacent; communal field area is optional.
- **Dependencies:** generalises `VillageProduction` from a single barley crop. BV-031 transport carries typed crop units. **FIELD-002** (millet/wheat/legumes) is needed for visuals; FIELD barley exists.
- **Evidence:** crops E strong; seasons E (interpretive and regional); proportions R.
- **Observer value:** high. It shows crop diversity and spreading labour across the year, which is AR24's explicit explanation.
- **Anachronism risk:** none if modern crops are excluded. Avoid "crop rotation science" framing.

### F2. Seed-corn reserve

- **Visible:** after harvest a portion goes into a separate "seed" jar. In spring, sowers fetch seed from it. Labels read "seed stock" vs "food stock".
- **Inputs → outputs:** harvested units → seed stock (locked from cooking) → sowing.
- **R parameter with derivation:**
  - H15 sowing rate: 400 caryopses/m² × 25–30 g per 1,000 grains = 10–12 g/m² = **100–120 kg/ha clean-grain equivalent**. This is the modern recommended upper rate, applied to a landrace.
  - S22 yield (M4) 600–800 kg/ha → seed ≈ **12.5–20%** of a harvest.
  - At H15's own 1.7–1.8 t/ha (chernozem experiment) → ~6–7%.
  - **Default `SEED_FRACTION` = 2 of 10 units (20%)** for Březnice's poorer cambisols (S22 p. 3). Tunable 1–2.
- **Rule:** cooking/grinding may not consume seed stock while sowing is pending. If seed is short, a smaller plot is sown and the plot visibly shrinks.
- **Season:** set aside in summer/autumn, drawn in spring/autumn.
- **Scope:** household.
- **Dependencies:** BV-031 storage capacity (`HOME_CAPACITY = 30`) must count seed; it needs a separate ledger and persistence fields. Currently `SOW_TICKS` creates a crop from nothing. **This is the main "free input" to remove.**
- **Evidence:** need for seed is a logical certainty; ratio R from experiment plus model input.
- **Observer value:** very high. It explains why a hungry household does not eat everything.
- **Risk:** a starvation spiral. Mitigate with the R safety rule "seed protected even under unmet need", plus a minimum plot.

### F3. Threshing and winnowing at the house

- **Visible:** carried sheaves are beaten and tossed on a cleared spot near the house; a chaff/straw heap grows.
- **Inputs → outputs:** 1 "sheaf" unit → 1 grain/spikelet unit + chaff/straw by-product token (+ weed seed into waste).
- **R parameters:** `THRESH_TICKS` ≈ harvest ticks (120); daytime, dry seasons only.
- **Season:** summer and autumn.
- **Scope:** household.
- **Dependencies:** sits between BV-031 delivery and storage. The by-product feeds F9 (fodder/bedding) and the sibling's clay/pottery chain (temper, C19).
- **Evidence:** processing waste on site E (S22, SP23, C19); method R.
- **Observer value:** medium-high. It is a visible activity and creates a by-product link.

### F4. Dehusking and grain cleaning (hulled cereals)

- **Visible:** pounding or rubbing at the quern before fine grinding; glumes collected.
- **Inputs → outputs:**
  - hulled wheat: 4 spikelet units → 3 clean grain units + glumes (**ratio 0.75**, from H15 p. 31, experiment).
  - barley/millet: 1 → 1 with an extra processing step, R. Do not invent a hull ratio for them.
- **R parameters:** `DEHUSK_TICKS` similar to grinding; it may share the WORK quern station.
- **Season:** after threshing, or ongoing "as needed" (stored as spikelets, dehusked in small batches; R choice).
- **Scope:** household.
- **Dependencies:** adds a step before `grind` in `VillageProduction`/`VillageEconomy`; uses WORK quern.
- **Evidence:** glume-base dominance among wheat finds E (SP23); ratio E (experiment).
- **Observer value:** medium. It explains the glume waste found archaeologically.

### F5. Meal types: porridge, flour food, pulse stew

- **Visible:** different pots/actions. Millet or groats boiled whole needs little or no fine grinding; flour food needs grinding; pulse stew boils pulses.
- **Inputs → outputs (R):**

  | Recipe | Inputs | Output |
  |---|---|---|
  | Porridge | 1 millet unit (or 1 groats unit) + water + fuel | 48 portions |
  | Flour food | 1 flour unit + water + fuel | 48 portions (current) |
  | Pulse stew | 1 pulse unit + water + fuel | 48 portions |

  - Grinding cost differences are R, derived from B20: coarse groats ≈ 0.8 kg/120 min vs fine flour 0.67–1.09 kg/120 min. Whole millet needs no grinding.
  - Suggested `GROATS_TICKS ≈ 0.5 × GRIND_TICKS` (R). Whole millet: 0 grinding ticks.
- **Choice rule (R):** prefer the recipe whose inputs are in stock and need the least labour, with a soft rotation for variety, so no single crop is used up first.
- **Season:** year-round.
- **Scope:** household.
- **Dependencies:** BV-029 cooking (240 ticks, 48 portions); BV-033 fuel unit per cooking batch; water consumption (F11). **POTTERY-003** bowls/cups and the existing POT; **KILN-001** hearth.
- **Evidence:** starch of cereals and legumes on querns, boiled meat, casein are E (SP23, K22). Dishes are R/F.
- **Observer value:** high. It shows that grinding is avoidable labour and makes diet variety visible.

### F6. Household storage, losses and lean-season shortfall

- **Visible:** sunken jar(s) inside or beside each house fill after harvest and visibly drain through winter and spring. An occasional "spoiled" event removes a unit. A pit may be dug in autumn.
- **Inputs → outputs:** grain/pulse units ↔ store; loss events → units removed (into waste).
- **R parameters:**
  - Jar capacity per household. Keep BV-031's 30 (R) or split it as jar 20 + pit 10. Seed has its own jar (F2).
  - **Loss: no sourced rate.** Propose a designer default of 0–1 unit per household per season, with the event logged and labelled R. Use a lower rate for millet (O24: suitable for long-term storage).
- **Season:** filled summer/autumn; drawn year-round; shortfall in spring.
- **Scope:** household. A shared pit is optional (Kuna's "pit per household per year" hypothesis is household).
- **Dependencies:** BV-031 capacity and conservation (loss must be an explicit conserved sink). BV-032 overview "current stores vs cumulative". **STORE-001** (on HOLD) for the jar/pit asset.
- **Evidence:** jar/pit features E (K22); contents not evidenced (SP23); losses R.
- **Observer value:** high. It produces the seasonal hunger curve and a winter story.
- **Risk:** do not show stored crops as excavated fact.

### F7. Seasonal gathering

- **Visible:** individuals walk to scrub or woodland edge and return with nuts, fruit or greens. Children could be gatherers in a fictional household (F).
- **Inputs → outputs:** labour + source patch (seasonal, finite per season) → food units.
  - hazelnut / sloe / berries → direct small food portions;
  - acorns → acorn unit → (dry, shell, grind) acorn flour, or pig/animal fodder.
- **R parameters:**
  - Per-trip yield of a small fraction of a unit (e.g. 1/4) and a per-season patch cap per household.
  - Gathered food stays **≤ ~10%** of annual household food. This is a design cap, motivated by "only in small quantities" (AR24 p. 181) and the 4% share of impressions (C19 p. 283), **not a measured diet share**.
  - Acorn grinding at ~half the cereal rate (B20: 0.43–0.49 vs 0.67–1.09 kg/120 min).
- **Season:** spring greens; late summer berries; autumn hazel, acorn, sloe.
- **Scope:** household.
- **Dependencies:** VEG oak/hazel exist; gathered units join the BV-029 food pool; carry via BV-031 typed cargo.
- **Evidence:** acorn, hazel and sloe local E (C19 impressions); greens and wild seeds E-interpretive (SP23).
- **Observer value:** high. Links woodland to food; the acorn dual use is a good learning page.

### F8. Herding and pasture rotation

- **Visible:** each morning (spring–autumn) a herder leads cattle/sheep out from a pen to pasture or woodland edge and back before dusk. The animals water at the stream.
- **Inputs → outputs:** herder labour-day + pasture → animals fed (no fodder draw); dung partly lost on pasture.
- **R parameters:**
  - One herder per day for the whole village on a household rota. This is R, and is the one place a **community** rota is recommended for labour efficiency.
  - Herd per household: unsourced. **F default 1–2 cattle + 2–4 sheep** for visual readability. Label F.
  - S22's 6.25 ha grazing per family (Iron Age comparator) is context only.
- **Season:** spring to autumn; none in deep winter.
- **Scope:** household-owned animals, communally herded (R).
- **Dependencies:** **ANIMAL-001** (cattle/sheep) and FENCE-001 (pen); water at WATER; must not cross FIELD (S22 p. 9: grazing regulated to protect crops). Movement/route system.
- **Evidence:** livestock products E (SP23); species and roles regional E (KY16); herding regime R.
- **Observer value:** very high visually.
- **Risk:** don't present goats, horses, chickens or dogs as evidenced locally. "Poultry" proteins need S25 review.

### F9. Winter fodder: leaf fodder, hay, straw

- **Visible:** in summer, villagers lop leafy branches and bundle them to dry, and cut meadow grass. Bundles stack by houses or byres. In winter, a daily feed draw shrinks the stack.
- **Inputs → outputs:** labour + woodland/meadow → fodder units; chaff/straw (F3) → low-value fodder. Daily draw per animal in winter.
- **R parameters:**
  - `FODDER_PER_ANIMAL_PER_WINTER_DAY` is a design rate with no source value.
  - Straw counts as **half value** (R ratio, motivated by H15: straw is nutritionally insufficient, used only if better forage is absent; no numeric factor given).
  - If fodder runs out: an animal "hungry" counter (capped, no death), milk stops, and an optional autumn culling decision. Culling is R and needs a sensitive presentation.
- **Season:** cut in summer; consumed in winter.
- **Scope:** household.
- **Dependencies:** ANIMAL-001; VEG oak/hazel (lopping); FIELD straw from F3; storage space.
- **Evidence:** winter leaf fodder from the forest is E-interpretive (S22 p. 3, citing an Italian Bronze Age comparator); straw value E (experiment).
- **Observer value:** high. Shows the summer work that winter depends on.

### F10. Milk, meat, dung and wool outputs

- **Visible:**
  - Milking near the pen (spring–summer).
  - Occasional slaughter and boiling of meat (an event, not a routine animation).
  - Dung carried to fields in spring.
  - Sheep plucked or shorn in late spring. Shearing tools are not verified here; plucking is safer R.
- **Inputs → outputs:**
  - fed animal-days → milk portions (seasonal);
  - animal → meat portions + hide (+ wool → sibling's textile chain);
  - stalling days → dung → small sowing bonus on a plot.
- **R parameters:** all design. Keep dairy a **supplement** (casein detections are E presence, not quantity).
- **Season:** milk spring/summer; slaughter late autumn (R: fodder limit); manure spring.
- **Scope:** household.
- **Dependencies:** F8/F9; the BV-029 food pool; the sibling's textile/loom chain (LOOMWEIGHT-001 clay weights; function unresolved).
- **Evidence:** casein, beef, pork, dung E (SP23, preprint); boiled meat E (K22); regional milk and wool E (KY16); volumes R.
- **Observer value:** medium-high.

### F11. Water consumption beyond drinking

- **Visible:** cooking draws from the household's delivered water.
- **Inputs → outputs:** cooking batch consumes `WATER_PER_COOK` units from household water.
- **R parameter:** 1 water unit (one 3-unit delivery feeds 3 batches; R).
- **Season:** year-round.
- **Scope:** household.
- **Dependencies:** BV-029 explicitly deferred water consumption. The existing water store is **cumulative delivered water**, so this function must add a consumable balance without breaking that ledger. WATER asset exists.
- **Evidence:** none local. R.
- **Observer value:** medium. It makes water trips purposeful.

### F12. Firewood demand and woodland depletion (extends BV-033)

- **Visible:**
  - Villagers fetch wood from the nearest woodland patch.
  - The cleared zone around the village slowly widens, so trips get longer.
  - Bigger stockpiles appear before winter.
  - Winter heating adds daily demand.
- **Inputs → outputs:** labour + distance → fuel units; cooking (BV-033) and winter heating (R) consume fuel; patch regrowth over years.
- **R parameters:**
  - Fuel per cooking batch: 1 (BV-033).
  - Heating: +1 fuel per household per winter day (design).
  - Near-patch capacity per season, then the next ring. Rings are R, scaled by S22's 15/30/60-min zones (≈ 1.1 km per 15 min on the model's Tobler basis, p. 5) compressed to map size.
- **Season:** collect all year with an autumn peak; heating in winter.
- **Scope:** household collection; woodland shared (C).
- **Dependencies:** BV-033 (queued) typed transport; **KILN-001** hearth + firewood asset; VEG oak/hazel; pottery firing demand belongs to the sibling's craft chain.
- **Evidence:** firewood from the surrounding forest and a cleared vicinity are E-interpretive (S22 p. 10); rates R.
- **Observer value:** high (landscape change).

### F13 (cross-cutting). Labour capacity and seasonal priorities

- **Visible:** inspector shows each person's capacity and current priority. A household chooses jobs by seasonal priority and need.
- **R parameters:**
  - Members: S22 implies 5 per house; the game uses 4/3/3. Keep it.
  - Capacity weights (F): adult 1.0, older child 0.5 (light tasks: gathering, herding), young child 0, elder 0.5 (processing at home).
  - No gender assignment (prototype brief).
- **Priority order (R):**
  1. Protect seed and deliver held crop (BV-031).
  2. Season-critical fieldwork (sowing, harvest).
  3. Cooking when food < 2 days.
  4. Grinding/dehusking.
  5. Fodder/fuel stockpiling.
  6. Gathering.
  7. Maintenance.
- **Dependencies:** BV-029's existing priority logic; DEVELOPMENT_PLAN "purposeful inhabitants".
- **Observer value:** explains why people do what they do.
- **Risk:** avoid a generic scheduler framework (BV-029 rule).

---

## 5. Ranked recommendations (top 5) — draft tickets

Proposals only. Ticket keys are placeholders for the manager to assign.

### 1. BV-0xx — Seed reserve and multi-crop sowing calendar (F1 + F2)

Status: proposal. Owner: simulation engineer. Depends on accepted BV-029/BV-031; FIELD-002 art optional (use existing FIELD with R tint until then).

**Outcome:** remove the crop-from-nothing input. Households set aside seed after harvest and draw it to sow. Barley, millet and a pulse are sown in spring; wheat is optionally sown in autumn. Crops ripen in different seasons, and stocks and plots show what is seed and what is food.

**R rules:**
- `SEED_FRACTION` 2/10 per crop, derived in §4 F2 from H15 sowing rate and kernel weight with S22 yield. Tunable.
- Crop shares per household 4/3/2/1 (barley/millet/pulse/wheat). These are R, not field areas.
- Millet and pulses harvest in autumn; barley and wheat in late summer.
- Seed is never cooked while sowing is pending. A short seed stock shrinks the next plot.
- First-year bootstrap seed is an explicit, labelled R starting stock (not silent food).

**Acceptance:**
- Crop/seed/food conservation per crop and household across ≥ 3 years.
- No sowing without seed.
- Partial-seed plot shrink is visible.
- Old-save migration gives legacy households a labelled initial seed stock.
- Speed/partition/pause determinism.
- HUD shows seed vs food.
- Full `./check.sh`, independent Standards/Spec review.

### 2. BV-0xx — Threshing, dehusking and meal types (F3 + F4 + F5)

Status: proposal. Depends on 1 and BV-033 (fuel per cooking batch).

**Outcome:** the harvest arrives as unthreshed units and is threshed and winnowed at home, producing a chaff/straw by-product. Hulled wheat is dehusked at the quern (0.75 yield, H15 experiment). Households cook porridge from whole millet or groats, flour food from flour, and pulse stew from pulses. They pick the least-labour recipe they can afford, with soft variety. Grinding stays daytime work at the WORK quern; cooking uses POT and the BV-033 hearth.

**R rules:**
- `THRESH_TICKS ≈ HARVEST_TICKS`.
- `GROATS_TICKS ≈ ½ GRIND_TICKS`; whole millet needs no grinding (B20 experiment ratios).
- 48 portions per batch for every recipe (R, unchanged scale).
- Chaff/straw is a by-product counter that F9 or the sibling's clay chain can use.

**Acceptance:**
- Atomic multi-input cooking (food + water + fuel).
- Per-recipe conservation.
- No single-crop exhaustion deadlock.
- Observable grinding-time difference between recipes.
- Learning page cites SP23/B20/H15 with E/R labels.

### 3. BV-0xx — Household storage, losses and lean season (F6)

Status: proposal. Depends on 1; STORE-001 asset on HOLD, so use the existing POT as an R proxy.

**Outcome:** each house has a food jar and a seed jar, plus an optional autumn pit. Stores visibly fill after harvest and drain to a spring low. Rare logged loss events remove a unit. Shortfall feeds the existing capped unmet-need counter: no deaths, no bootstrap food.

**R rules:**
- BV-031 capacity is split into jar and pit.
- Loss is 0–1 unit per household per season (design value, no source), lower for millet (O24).
- A pit lasts one year (K22 hypothesis, SP23 citing Neustupný).
- Loss is an explicit conserved sink.

**Acceptance:**
- Conservation including losses.
- Deterministic loss events under seed/save.
- Overview (BV-032) separates current store, losses and cumulative harvest.
- One-household shortage visible despite village surplus.
- Text never claims excavated stored contents.

### 4. BV-0xx — Seasonal gathering and acorn use (F7)

Status: proposal. Depends on BV-031 typed cargo (or BV-033's typed transport).

**Outcome:** in autumn, villagers gather hazelnuts, acorns and sloes from oak/hazel VEG patches. In spring and summer they gather greens and berries. Gathered food is a capped supplement that matters most in the lean season. Acorns either become fodder (if animals exist) or are dried and ground at the quern at a slower rate.

**R rules:**
- Per-trip 1/4 unit; per-season patch caps.
- Gathered food ≤ ~10% of annual food (design cap motivated by AR24/C19 "small quantities").
- Acorn grinding at half the cereal rate (B20 experiment).

**Acceptance:**
- Finite patches with seasonal refresh.
- Gathering yields to sowing and harvest priority.
- Conservation.
- Learning page explains acorn impressions (C19 p. 286/295) and the unresolved food-vs-fodder question.

### 5. BV-0xx — Herding, winter fodder and animal outputs (F8 + F9 + F10, minimal)

Status: proposal. Depends on ANIMAL-001 (pending) and FENCE-001; independent of crop tickets except straw (F3).

**Outcome:**
- A village herder rota leads household cattle/sheep to pasture and back daily from spring to autumn, watering them at the stream.
- In summer, villagers cut leaf fodder and hay into stacks. In winter, animals are stalled and fed from household fodder; straw is used at half value.
- Outputs: seasonal milk portions into food, autumn culling to fodder capacity as a muted event, and dung for a small sowing bonus.

**R/F rules:**
- Herd sizes 1–2 cattle and 2–4 sheep per household (F).
- All rates are design values.
- Animals never die of hunger in this slice: capped hunger stops milk.
- Herding never crosses sown fields (S22 p. 9).

**Acceptance:**
- Fodder conservation and the winter draw.
- No herder deadlock with sowing/harvest peaks.
- Animal state persists.
- Labels distinguish regional evidence (KY16) and local protein detections (SP23) from F herd sizes.

**Next after top 5:** F12 woodland depletion and winter heating as a BV-033 follow-up; F11 water consumption; F13 labour-capacity inspector.

---

## 6. Open questions, inaccessible sources, bibliography

### 6.1 Open questions for the manager or a specialist

1. **S25 vs SP23:** do the published protein results (poultry, casein) and crop proportions match the preprint? This affects the chicken exclusion and dairy claims. S25 must be read before any learning text quotes them.
2. **"Březnice – U Františka" (AR24 Tab. 2 site 37, FBA, 445 m):** is this the same locality as our Ha A2–B1 site, or a different findspot? AR24's LBA rows do not list Březnice explicitly; Hvožďany (LBA) is listed. Not resolved.
3. **S22 field-system figure "562 to 7.5 ha"** is garbled in the PDF text. Check the publisher HTML. Table 2 uses 5 and 7.5 ha.
4. No local or regional source was found for **spoilage rates, fuel per hearth-day, herd sizes, milk yields, tillage/harvest labour hours** or **water needs**. All are R design values. A specialist could supply regional experimental figures, e.g. Danielisová's České Lhotice model (Iron Age), Neustupný 1986, Dreslerová 1996.
5. **Winter vs spring wheat at Březnice** is interpretive (SP23 cites Slovak data). Weed-ecology analysis (AR24 p. 185 suggests it) is not available here.
6. **Hay-cutting and harvesting tools** (sickle forms, absence of long scythes) are not verified in inspected sources; that is outside my scope (see the sibling doc / BRONZE-001).
7. **Location of animals in winter** (inside houses or separate byres): not evidenced locally.
8. Whether **community-level pooling** (shared herding, harvest help) should exist at all. That is a design choice; BV-032 records household-first as a simulation choice.

### 6.2 Not accessible this session

- Šálková et al. 2025 (*Archaeological Prospection*) publisher full text: blocked (web_fetch private-address block; curl HTML challenge). Repository handle 20.500.14178/3512 timed out.
- Zenodo 10.5281/zenodo.6475797: HTTP 403 (traffic restriction).
- S22's model-input sources (Neustupný 1986; Dreslerová 1996; Danielisová 2008/2010; Jacomet & Karg 1996; Karg 1998): not retrieved.
- S22 Supplementary Tables 1–2: not retrieved.

### 6.3 Bibliography

- **S22** Šálková T., Vobejda L., Chvojka O., Beneš J., Vondrovský V., Kuna M., Křivánek R., Menšík P., Novák J. 2022. Extensive archaeobotanical data estimate carrying capacity, duration, and land use of the Late Bronze Age settlement site Březnice (Czech Republic). *Scientific Reports* 12:20323. https://doi.org/10.1038/s41598-022-24753-x — PDF read: https://naos-be.zcu.cz/server/api/core/bitstreams/7115b54d-fe44-4a16-9a8c-ea51b7a2400d/content (CC BY 4.0)
- **SP23** Šálková T., Budilová K., Kovárník J., Majer A., Novák J., Pavelka J., Strouhalová B., Vobejda L., Šťastný O., Kuna M., Chvojka O. 2023. Waste disposal processes and landfill management in Late Bronze Age inner periphery of the central Europe: Březnice settlement site (South Bohemia). Research Square preprint. https://doi.org/10.21203/rs.3.rs-2665597/v1 — PDF: https://www.researchsquare.com/article/rs-2665597/latest.pdf (CC BY 4.0)
- **S25** Šálková T. et al. 2025. Waste Management and Waste Disposal Detected by Combination of Analytical Methods: Late Bronze Age Březnice Settlement Site (South Bohemia). *Archaeological Prospection* 32:525–548. https://doi.org/10.1002/arp.1973 (not read this session)
- **K22** Kuna M., Chvojka O., Šálková T. et al. 2022. Deposition analysis and the hidden life of Bronze Age houses. *Journal of Anthropological Archaeology* 67:101433. https://doi.org/10.1016/j.jaa.2022.101433 — PDF: https://naos-be.zcu.cz/server/api/core/bitstreams/5d93fa40-360f-4931-8205-53a35c41cb0b/content (CC BY-NC-ND 4.0: cite/link only)
- **C19** Chvojka O., Menšík P., Šálková T., Kuna M. 2019. Tkalcovská závaží nebo podstavce pod rožně? Hliněná závaží ze sídelního areálu z mladší doby bronzové u Březnice (okr. Tábor) z pohledu archeologie a archeobotaniky. *Archeologické rozhledy* 71(2):267–308. https://doi.org/10.35686/ar.2019.11 — PDF: https://www.arup.cas.cz/wp-content/uploads/2019/11/4_Chvojka_267-308_web.pdf
- **KY16** Kyselý R. 2016. Historie chovu domácích zvířat v Čechách a na Moravě ve světle archeozoologických nálezů. *Živa* 2016(5):225–229. https://ziva.avcr.cz/files/ziva/pdf/historie-chovu-domacich-zvirat-v-cechach-a-na-mora.pdf (reprint forbidden; cite only)
- **AR24** Pokorná A., Kočár P., Šálková T. 2024. Changes in spectra of cultivated and gathered plants in the Bronze Age: A study based on archaeobotanical data from the Czech Republic. *Archeologické rozhledy* 76(2):173–188. https://doi.org/10.35686/AR.2024.223 — PDF: https://archeologickerozhledy.cz/index.php/ar/article/download/223/252
- **H15** Hejcman M., Hejcmanová P. 2015. Yield and nutritive value of grain, glumes and straw of *Triticum dicoccum* produced by prehistoric technology in comparison to *T. aestivum* produced by modern technology. *Interdisciplinaria Archaeologica (IANSA)* VI(1):31–45. https://doi.org/10.24916/iansa.2015.1.3 — PDF: https://www.iansa.eu/papers/IANSA-2015-01-hejcman.pdf
- **B20** Bofill M., Chondrou D., Palomo A., Procopiou H., Valamoti S. M. 2020. Processing plants for food: experimental grinding within the ERC-project PLANTCULT. *Journal of Lithic Studies* 7(3). https://doi.org/10.2218/jls.3079 (CC BY 4.0)
- **O24** Orfanou E., Zach B., Rohrlach A. B. et al. 2024. Biomolecular evidence for changing millet reliance in Late Bronze Age central Germany. *Scientific Reports* 14:4382. https://doi.org/10.1038/s41598-024-54824-0 (CC BY 4.0)
- BR24 Breu A., Risch R., Molina E., Friederich S., Meller H., Knoll F. 2024. Pottery spilled the beans… *PLOS ONE* 19(5):e0301278. https://doi.org/10.1371/journal.pone.0301278 (abstract only; not used for claims)
- Z22 Kuna M. et al. 2022. Sídliště z mladší doby bronzové v Březnici (Česko): data pro depoziční analýzu. Zenodo. https://doi.org/10.5281/zenodo.6475797 (not accessible this session; inherited counts only)
- Project files: `content/research/prototype-brief.md`; `content/research/next-batch/{README,settlement-features}.md`; `art/handoffs/bronze-bohemia-opus-v2/references/{SOURCES,research-notes}.md`; `team/tasks/BV-029.md`, `BV-031.md`, `BV-032.md`, `BV-033.md`.

No images were downloaded for this document.
