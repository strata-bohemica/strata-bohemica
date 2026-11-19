# Economy research B — crafts, materials, maintenance, exchange and social economy

Research B, 2026-11-06. This is a **research submission**, not historical approval and not a dispatched ticket. Setting: a fictional household cluster inspired by Březnice near Bechyně, South Bohemia, Ha A2 / Ha A2–B1, c. 1150–1000 BCE. Sibling document `subsistence.md` (Research A) owns food, fields, animals, fuel demand and the Šálková 2022 land-use model; this document cites that model only where it bears on timber, houses and settlement size.

Labels: **E** = bounded observation from an inspected, identified source (page/section given). **R** = reconstruction, inference, analogy (ethnographic/experimental/other region) or design choice. **F** = fiction. Regional comparators are labelled with region and period and are **not Březnice evidence**. Game parameters are always R and show their derivation. Negative findings ("not found in inspected sources") mean unresolved, not absent.

---

## 1. Scope, method and sources actually read

**Scope.** Household crafts and their chains (pottery, textiles, clay weights, woodworking/building maintenance, stone, leather/bone); the bronze economy (copper/tin import, ingots, scrap, hoards, casting); salt; long-distance routes; pre-monetary exchange, intra-village sharing and communal work; deposition as an economic sink; status/wealth evidence. Food production, livestock outputs and fuel demand are referenced only as inputs.

**Method.** Full-text reading of the local primary sources (PDF text extraction, page-anchored), direct queries of the Zenodo Březnice database (Excel tables), targeted OpenAlex/DOI searches for open-access Central European papers, and publisher landing-page abstracts for two closed papers. No logins, paywalls bypassed, museum contact or general web search. Figures in NC-ND/NC sources were not copied. No images were downloaded (optional item skipped to keep effort on evidence).

| ID | Source | Access / licence | What was inspected |
|---|---|---|---|
| S-SA22 | Šálková et al. 2022, *Sci Rep* 12:20323 | University repository PDF, CC BY 4.0 | Full text pp. 1–13: site (p. 3), model inputs (p. 5), results (pp. 6–7, Table 1), discussion (pp. 8–12, Table 2), conclusion (p. 13) |
| S-KU22 | Kuna et al. 2022, *J. Anthropol. Archaeol.* 67:101433 | University repository PDF, **CC BY-NC-ND 4.0 — cite only, no reuse of figures/text** | Full text pp. 1–13 |
| S-CH19 | Chvojka, Menšík, Šálková & Kuna 2019, *Archeologické rozhledy* 71: 267–308 | ARÚ institutional PDF (no licence stated; treat as cite-only) | pp. 270, 278–279, 289, 291–296, 301–302 (Czech text; German summary checked) |
| S-ZEN | Kuna, Němcová & Chvojka 2022, Zenodo 10.5281/zenodo.6475797 | CC BY 4.0 | Excel tables `_objekty`, `_keramika_DTB1_jedinci_v4`, `_keramika_DTB2`, `_keramika_mazanice_zavazi_v2`, `_mazanice`; `EN_comments.pdf` |
| S-SA25 | Šálková et al. 2025, *Archaeological Prospection* 32: 525–548 | Not re-read here; reused only via existing bounded notes (opus-v2 research-notes, BV-032) | Storage pits/vessels lacked stored crops (§4.1); individual household economies (abstract/discussion) |
| S-KR24 | Chvojka, Jiráň, John, Kmošek, Thér & Zachar 2024, *Archeologické rozhledy* 76: 221–256 (Krtely hoard) | Journal PDF, CC BY 4.0 | Full text pp. 221–252 |
| S-KM20 | Kmošek et al. 2020, *Archaeol. Anthropol. Sci.* 12:234 (Staré Hodějovice ingots) | **Closed**; abstract only (Springer landing page) | Abstract |
| S-KM25 | Kmošek et al. 2025, Domažlice casting cakes vs Mutěnín ore | Research Square preprint, CC BY 4.0 (published version in AAS is closed) | Abstract, introduction p. 2 |
| S-PE16 | Pernicka, Lutz & Stöllner 2016, *Archaeologia Austriaca* 100: 19–55 (Mitterberg) | Open (publisher PDF) | Abstract, pp. 25–28, 42 |
| S-RA19 | Radivojević et al. 2019, *J. Archaeol. Res.* 27: 131–185 | Open, CC BY 4.0 | Abstract, pp. 161–162, 165–166 |
| S-MO21 | Mödlinger, Trebsche & Sabatini 2021, *PLoS ONE* 16: e0254096 (Prigglitz-Gasteil) | Open, CC BY 4.0 | Abstract |
| S-RK19 | Reschreiter & Kowarik 2019, *Archaeologia Austriaca* 103: 99–136 (Hallstatt BA salt mine) | Open (diamond OA) | Abstract, preface p. 99 |
| S-LA24 | Lane 2024, *Študijné zvesti AÚ SAV* 71: 89–113 (hoards as risk management) | Open | Abstract only |
| S-PO24 | Pokorná, Kočár & Šálková 2024, *Archeologické rozhledy* 76: 173–188 | Open | Abstract; LBA results p. 181; Tab. 3 p. 182; oilseeds p. 184 |
| S-BA26 | Baron 2026, *Craftwork in Small-Scale Societies of the Central European Bronze Age*, CUP Elements | Open, **CC BY-NC 4.0** | §5 “Two-track crafting” pp. 25–29; §6 “Seasonality” pp. 29–41 |
| S-SB18 | Sabatini, Earle & Cardarelli 2018, *PPS* 84: 359–385 (Montale) | Open, CC BY 4.0 | Abstract, pp. 360–361, 364 |
| S-DO23 | Doležalová, Řídký & Pilař 2023, *Archeologické rozhledy* 75: 109–131 (rhyolite querns) | Open | Experimental grinding, p. 117 |
| Repo | `content/research/next-batch/material-culture.md`, `settlement-features.md`, opus-v2 `SOURCES.md`/`research-notes.md`, `team/tasks/BV-029/031/032/033`, `DEVELOPMENT_PLAN.md`, `scripts/village_production.gd`, `village_simulation.gd`, `village_economy.gd` constants | Project files | Current mechanics and earlier bounded claims |

**Tried but not accessible:** Tichá hoard paper (Chvojka & John 2022, CU DSpace — request timed out); Kmošek et al. 2020 full text (closed); Chvojka, Kuna, Menšík et al. 2021 Březnice monograph *Rituály ukončení a obnovy* (print; only TOC inspected by Research A — includes a 1–2 page “Kovové artefakty” section, p. 140, not seen); Kyselý 2016 (*Živa*, animals — not needed for this scope; cite-only per assignment); open-firing experiment (Hrčak 156651, returned HTML only).

---

## 2. Findings per topic

### 2.1 Site scale and the house as the economic unit

- **E** — Site ~13 ha; 1,090 m² excavated in six seasons 2005–2019; 102 sunken features excavated, hundreds more from magnetometry (S-SA22 p. 3). ~70 long pits (“trenches”) inferred, 21 excavated (S-SA22 p. 3).
- **E** — Occupation modelled 73–264 years (95%), probably 107–192 (68%); typology 100–150 years (S-SA22 pp. 3, 10).
- **E (as a model assumption, not an observation)** — Each long pit = one house; houses ~25 years on average; 70 houses built over the settlement life (S-SA22 pp. 5, 10). Kuna gives house life “one generation (20–25 years)”, explicitly “based rather on general models than on empirical data” (S-KU22 p. 10).
- **E (model output)** — Table 2 multiplies houses by 5 people; land-use scenarios give at most ~20 contemporaneous houses (intensive, ~90 years), ~14 (extensive, ~126 years) or ~9 (optimal fallow, ~192 years) (S-SA22 pp. 11–12, Table 2). The game's 3 households / 10 people is far below any of these: it is a household *cluster*, not the settlement (R).
- **E** — No house plans survive at Březnice; house form is assumed from other regions: oblong above-ground buildings 5–8 m wide, post walls, wattle and daub (S-KU22 p. 8). Long pits occur singly or in groups of 2–4; ~2–6 m apart = asynchronous, ~10 m apart = possibly neighbouring contemporaneous houses; pairs/fours with other features are tentatively “homestead clusters” (S-KU22 pp. 7–8).
- **E** — Four of five sunken storage vessels lie ~2.5 m west of long pits, read as roughly mid-house (S-KU22 p. 8).
- **E** — Kuna calls Březnice “most probably … a usual agricultural settlement of its time” (S-KU22 p. 8). Šálková 2025 interprets individual household economies with similar crop processing across households (via BV-032; not re-read).

### 2.2 Pottery: production, use, breakage, discard

- **E** — 11,546 pottery individuals in the database; 449 classified to type: storage jars 146 (143 coarse), bowls 133, amphorae 71, cups 56, pots 26, biconical 14, beakers 2, colander 1; median wall thickness storage jar 11, bowl 5, cup 4 (units probably mm) (S-ZEN DTB1, via material-culture.md §1, re-queried).
- **E** — Deposition-analysis sample: >30,000 sherds (~522 kg), ~500 loom weights and fragments (123 kg), ~10,000 daub fragments (~130 kg) (S-KU22 p. 4). Over half the long pits exceed 1,000 sherds/m³ — “extraordinary” even for LBA Bohemia (S-KU22 p. 5).
- **E** — Pottery in long pits is *tertiary refuse*: <1.5 fragments per vessel individual; 98.2% of vessels <5% preserved; joins dispersed through fills; abraded breaks. It was first accumulated in a dump near the house (“provisional discard”), trampled and handled, then burned and redeposited (S-KU22 pp. 5–7). Pottery grit 1–25 g/dm³ in flotation samples vs pottery 1–90 g/dm³ (S-KU22 p. 6).
- **E** — More than half the sherds are secondarily burned, ~10% deformed; technological analysis indicates 1,000–1,200 °C, compatible with a house fire or controlled event, not an open-air accidental fire (S-KU22 p. 6). This is *post-use* burning, not original firing temperature.
- **E** — Kuna suggests the dump beside the house may have stored coarse sherds for reuse, e.g. as temper; grog temper is “documented in the LBA” (citing Roztoky, central Bohemia, Final Bronze Age — regional comparator) (S-KU22 p. 10). At Březnice itself this reuse is **R**.
- **E** — A feature classified as a clay pit (`O-hliník`, 2005-O-05, ~12 m², 0.3 m deep) exists on the site; its later fill held 2,585 sherds (38.1 kg) (S-ZEN `_objekty`, `_keramika_mazanice_zavazi_v2`). Kuna also lists “a clay pit” among feature types (S-KU22 p. 4). Clay was therefore dug on site at least once (E); what it was used for (daub vs pottery) is R.
- **E** — Boiled-meat proteins were found on artefact surfaces and soil from long pits (Pavelka 2021, via S-KU22 p. 10): cooking in vessels.
- **R / regional** — Large LBA storage jars (Wrocław, Poland) can reach ~1 m and >1,000 l; coiling heavy wet clay needs timed drying to avoid collapse; fine “table” vs coarse “kitchen” is not a clean skill divide (S-BA26 pp. 27–29). Hand-building (coiling) is the method presupposed; no wheel (R; no wheel evidence sought or found).
- **Not found** — No pottery kiln is demonstrated at Březnice. The eleven `O-pec` records are burnt-surface/fill features, not proven ovens or kilns (material-culture.md §1 item 5; S-KU22 p. 4 “kilns (features with a burnt surface or fill)”). Firing method is **R** (open/pit firing as default design choice).
- **E (anomaly)** — 21 DTB1 records describe “struskovitá hmota” (slag-like mass, 409 g total) in features 2005_O_01, 2007_O_01, 2007_O_05; one note says “possibly a piece of daub” (S-ZEN DTB1 `poznamka`). Given the 1,000–1,200 °C secondary burning, these are most plausibly vitrified ceramic/daub (**R**), not metallurgical slag. Do not model smelting from this.
- **R / ethnographic, Poland** — Pottery seasonality: clay dug spring–autumn and stockpiled before snow; vessels made Feb–Mar, May, July and from early September; first firing March/April; winter firing possible but harder and more fuel-hungry (S-BA26 pp. 32–34, citing Wójtowicz-Wierzbicka 2014 and Morysiński 2000). Ethnographic clay preparation “could have taken months or even years” (S-BA26 p. 32). Analogy only.

### 2.3 Clay weights and textiles

- **E** — Weights: pyramidal, usually 140–170 mm high; reconstructed mass mostly 1,600–1,800 g (20 of 45), range ~1,230–2,353 g, one 131 g miniature (S-CH19 pp. 278, 292). All fired: ~60% medium, ~20% low, rest high/over-fired; ~a third secondarily burned; **no unfired weights at Březnice** (S-CH19 pp. 279, 294).
- **E** — Largest groups: feature 1/05 — 28 weights + 44 fragments; 12/06 — 41 + 26; 5/07 — 12 + 19 (S-CH19 p. 278). The mass groups are waste deposited at one time, not looms in situ; mixed with sherds, quartz hammerstones (*křemenné otloukače*) and daub (S-CH19 pp. 270, 301).
- **E** — 1,745 plant impressions on 99 weights: grain impressions 57%, cereal processing waste (chaff, glumes, spikelets, straw) 38%; minor pulses and gathered fruits (acorns, hazelnuts, sloe stones). Authors infer deliberate collection of **unsorted crop-processing waste** as organic temper — “evidence of waste recycling in the LBA community” (S-CH19 pp. 294–295, 301).
- **E** — Temper composition differs between weights in the same deposit; weights were made “over a longer time, from different clay and material, probably by different makers” (S-CH19 p. 301); slight shape clusters may reflect individual makers' “handwriting” (S-CH19 p. 292).
- **E** — One weight's internal straw dated 1386–1217 cal BC, older than the site; authors float reuse of older clay/organic material, e.g. from an earlier building (S-CH19 p. 289). Single date — weak.
- **E** — Function unresolved: hole wear almost only in the *lower* part, so classic warp-weighted suspension is judged “rather unlikely”; base-up tying hypothesised; spit-support use cannot be excluded (S-CH19 pp. 291–293). Marks on tops: possible maker/owner/position marks — undecided (S-CH19 p. 293).
- **E** — Heavy weights (>2 kg) are often linked to thick wool cloth, but experiments have not proven it (S-CH19 p. 293). Weight deposits elsewhere include funerary contexts and, once, a hoard (Syrovín, Moravia) (S-CH19 p. 294). Possible deliberate fragmentation of weights “so they could not be used by a third person” is raised (S-CH19 p. 294); at Roztoky some weights may be non-functional imitations made for abandonment rituals (Roztoky, FBA, via S-CH19 p. 294).
- **E / regional** — Central European loom-weight groups interpreted as looms: e.g. Gars-Thunau 31+7 in rows (Ha B), Wallwitz 27 in a row (Ha A2–B1), Rötha-Geschwitz 20 in a double row, Polanowice 14 in two rows (S-CH19 Table 7, p. 296). Regional comparators for “how many weights per loom”, not Březnice facts.
- **E (negative)** — Flax is **not** in the Březnice crop list (millet, barley, emmer, einkorn, spelt, free-threshing wheat, lentil, pea, faba bean) (S-SA22 p. 6). In a 39-site Czech BA dataset, flax appears as one FBA linseed (Bavoryně); in the LBA only one poppy seed (Hvožďany) represents oilseeds (S-PO24 pp. 181, 184). Flax may still have been grown (documented regionally since the Neolithic, S-PO24 p. 184), but the simulation should not foreground linen.
- **E (negative)** — Spindle whorls were not verified for Březnice in inspected sources (material-culture.md §2). Animal bones are not preserved (acid soil), so sheep presence is unverified locally (material-culture.md §1 item 7).
- **R / analogy (Near East text + modern experiment, via Italy paper)** — ~124 working days to make a 3.5 × 3.5 m wool fabric from raw wool; ~67 of those days spinning; finer thread costs more (S-SB18 p. 364). Soay-like sheep yield ~0.3–0.9 kg wool/yr; ~4 kg wool for such a fabric (S-SB18 pp. 360–361). Use only for *ratios* (spinning dominates textile labour), not absolute times.
- **R / Italy MBA** — At Montale, 4,000+ whorls suggest village-level, community-based yarn production possibly for exchange (S-SB18 abstract). Not applicable to Březnice as evidence.

### 2.4 Building, timber and maintenance

- **E** — Daub is under-represented: average ~21 kg pottery vs <6 kg daub per m³ of fill, although each house “must have used up to tons of daub” (S-KU22 p. 6, citing Haller & Gentizon Haller 2012). Interpretation: most daub was **removed for reuse before the house was burned** (S-KU22 pp. 10–11).
- **E** — Up to three plaster layers on Březnice daub (white coating); other BA sites up to eleven (S-KU22 p. 10). Plaster renewal is a recurring maintenance task (R for frequency).
- **E** — Clay balls occur at Březnice; Kuna floats storage of daub/clay for reuse as balls (S-KU22 pp. 11–12).
- **E (speculative in source)** — Very little fir charcoal in long pits, while fir occurs in post holes and as construction timber at Hvožďany: posts/beams may have been salvaged (S-KU22 p. 12; S-SA22 p. 10).
- **E** — Oak dominates charcoal and “was mainly used as construction material”; fir present in stake pits (S-SA22 p. 10). Firewood came from commonly available local woodland (S-SA22 p. 10).
- **E (model input, regional literature)** — Firewood for one farm from ~10 ha; ~125 ha of “cultural forest” per family for firewood, construction wood, food and forest pasture (S-SA22 pp. 5, 10). Forest was not the limiting factor (S-SA22 p. 10).
- **E** — A sunken storage feature contained three storage jars “inserted into each other”, read as gradual **renewal/replacement of a sunken jar over several years** (S-KU22 p. 10).
- **R / ethnographic** — Wattle rods (willow, hazel, birch, elm) are seasonal: cut after leaf fall, soaked for weeks, used before spring sprouting; wattle-and-daub repair timing is constrained by both rods and clay pits (S-BA26 pp. 39–40). Wickerwork was a fall/winter household task (S-BA26 p. 39).

### 2.5 Stone, bone, leather

- **E** — Saddle quern/grinding slab with grass, wheat and legume starch (opus-v2 B/C). Stone type and source not established in inspected sources.
- **E** — Quartz hammerstones occur in the weight deposits (S-CH19 pp. 270, 301). No use was studied.
- **R / experimental, Neolithic replica** — Einkorn on rhyolite replica: 1 kg grain → 977 g flour in 4 h; 4 kg → 3,869 g in ~12 h (S-DO23 p. 117). Order-of-magnitude anchor for grinding labour only (sibling scope).
- **E (negative)** — Bone/antler/leather not recoverable locally (acid soil). **R / Polish LBA** — bone tools ranged from quick knife-made awls “very likely by anyone” to compass-decorated antler pieces made with metal tools on the same sites (S-BA26 pp. 25–26).

### 2.6 Bronze: supply, scarcity, recycling, hoards

- **E (local)** — At Březnice: one sherd with a melted-on piece of bronze (S-ZEN DTB2, 2006_O_06). No moulds, crucibles, tuyères or bronze tools were found in the inspected datasets; the monograph's metal section was not seen. **No local casting evidence** in inspected sources.
- **E (South Bohemia, regional, slightly earlier Br D–Ha A1)** — Krtely hoard: 27 metal artefacts, 7,257.2 g, in/on a burial mound, with a vessel (S-KR24 pp. 221, 224). Tools, weapons and ornaments are tin bronze; the 12 ingot items (one whole cake ingot + 11 fragments) are copper (S-KR24 pp. 237–239, Tab. 2). Only 3 of 27 items are whole and undeformed; a pick and bracelets were probably deliberately broken/deformed — “probably not a collection of material intended for remelting”, rather a votive deposit (S-KR24 pp. 250–251).
- **E** — The Krtely pick is a Hallstatt-type miner's pick (as in the Hallstatt salt mines), reused as a chisel; a fragment of the same type is in the Holašovice hoard (South Bohemia) (S-KR24 pp. 221, 224–225, 238). Whole cake ingots are rare in Bohemian Urnfield hoards (Krtely is the sixth verifiable), mostly fragments (S-KR24 pp. 234–237).
- **E (abstract only)** — Staré Hodějovice hoard (South Bohemia, LBA): copper ingots mainly from Alpine ores (Trentino, Mitterberg, possibly Valais), transported as flat/plano-convex ingots from multiple sources and **refined and alloyed in South Bohemia**; results “refute the idea of prevailing copper recycling” (S-KM20 abstract).
- **E (preprint)** — West Bohemian casting cakes (late EBA/early MBA) are Alpine chalcopyrite copper; LBA exploitation of the local Mutěnín deposit “has not been proven” (S-KM25 p. 2).
- **E (Austria)** — Mitterberg produced ~20,000 t copper, mainly 16th–13th c. BC, declining at the main lode from the 11th c. BC; Urnfield metal is often mixed, making provenance harder (S-PE16 pp. 25–28, 42).
- **E (review)** — Scrap hoards appear from the mid-2nd millennium BC; scrap-for-recycling and ritual readings both remain open; recycling “may have become more substantial toward the end of the second millennium BC”; whether ingots acted as pre-monetary currency is “a key point of debate” (S-RA19 pp. 161–162, 165–166). Prigglitz-Gasteil (Lower Austria, LBA): imported copper alloys mixed/recycled with local copper (S-MO21 abstract). Lane reads Urnfield hoards (Attersee, Austria) partly as risk management/protection of goods (S-LA24 abstract).
- **R** — Synthesis for the game: bronze reached a South Bohemian farming cluster as finished tools/ornaments and copper ingot fragments via regional networks; some casting/alloying happened *somewhere* in South Bohemia (S-KM20), but not demonstrably at Březnice. Metal was scarce, curated and periodically withdrawn from circulation by deposition.
- **R / ethnographic via S-BA26 p. 39** — Metalworking was usually part-time even for skilled smiths, intensifying before/at harvest when cutting tools were heavily used (Rowlands 1971).

### 2.7 Salt and routes

- **E (as cited assumption)** — Březnice “was probably located on a long-distance route between the Alps and Central Bohemia, and it is generally assumed that copper and salt were imported along it” (S-SA22 p. 3, citing Šálková et al. 2019 “Crops along the trade routes?”). The long-pit custom may have spread along such routes (S-SA22 p. 8). This is an inherited assumption, not a demonstrated route at the site.
- **E (Austria)** — Underground salt mining at Hallstatt is attested from the Bronze Age, with 18 BA mining sites and surface evidence of large-scale meat production (S-RK19 p. 99). Hallstatt-type picks in South Bohemian hoards (Krtely, Holašovice) materially link the region to that salt-mining milieu (S-KR24 pp. 238–240).
- **Not found** — No briquetage or local salt production in inspected Březnice data. Salt at Březnice is **R** (plausible import, unquantified).
- **E** — Hvožďany, an equally dated settlement, lies ~5.5 km NW across the Lužnice (S-SA22 p. 3); elsewhere the centres are ~7 km apart, ~1 h walk (S-SA22 p. 5). Catchment ≤1 h walk (~3.5–4.5 km) (S-SA22 p. 5).
- **R / ethnographic** — Access to non-local goods (ores, salt, amber) and overland travel were seasonally limited by winter; off-peak farming months suit exchange (S-BA26 p. 39).

### 2.8 Exchange mechanisms, sharing and communal work

- **E (negative)** — No inspected Březnice source describes exchange mechanisms, sharing rules, kin structure or communal labour. Everything below is **R**.
- **E (debate exists)** — Fragmentation in hoards has been read as weight standardisation for “(pre)monetary use” *or* as decommissioning (S-KR24 p. 250); ingots as currency is debated (S-RA19 p. 161). For a game, this means: **do not model money, prices or standard units of exchange**.
- **R** — Appropriate mechanisms for a small pre-monetary farming community, as modelling choices: (a) generalised reciprocity inside the cluster (food/help given without counting exact return, but remembered); (b) balanced reciprocity with neighbouring settlements (gift for gift, delayed); (c) hospitality/feasting at life-cycle events; (d) obligations around marriage (bride-wealth or dowry are possibilities, unattested here — leave out or keep F); (e) tribute to distant elites — no local evidence; avoid. These are general anthropological categories, not findings.
- **R** — Communal work: house-raising, daub collection and harvest help are plausible collective tasks (wattle-and-daub houses needing “tons” of daub, S-KU22 p. 6), but no source inspected documents labour organisation.
- **E** — Feasting interpretations exist for LBA pits elsewhere (“feasting pits”, Switzerland; *Keramikgruben*), cited by S-KU22 p. 1 as comparators. Funeral feasts and spring “hunger gaps” constrain such events in Slavic ethnography (S-BA26 p. 38) — R.

### 2.9 Deposition as an economic sink

- **E** — Proposed Březnice house biography: construction → use and maintenance (dump accumulates) → abandonment with removal of reusable daub/timber → burning of the house and/or its remains → digging of the long pit after the fire and single-step backfilling with the burned dump → closing deposits of unburned fine vessels and (perhaps deliberately broken) loom weights → new house nearby (S-KU22 pp. 9–13, Fig. 9). 37 larger/complete fine vessels, never secondarily burned, form the closing deposits (S-KU22 p. 7). Authors see a ritual (“house burial”), not a cult, and reject a single catastrophic fire (S-KU22 pp. 12–13).
- **E (regional)** — Metal hoards (Krtely, Holašovice, Staré Hodějovice, Olešná) remove substantial metal from circulation in South Bohemia (S-KR24 pp. 236–237, 250–252; S-KM20).
- **R** — For the simulation, deposition is the main **sink** that keeps craft stocks from accumulating forever: pots go to the dump, the dump goes into the long pit, good vessels and weights are withdrawn deliberately, a house's materials are partly recycled and partly destroyed.

### 2.10 Status and wealth

- **E** — No house-level wealth differences are reported in inspected Březnice sources; the deposition differences analysed are functional/temporal, not status-based (S-KU22 pp. 5–8).
- **E (regional)** — Exceptional prestige items do circulate regionally (e.g. a cast-hilted Erding-type sword fragment, “only the third” Urnfield cast-hilt sword in South Bohemia) (S-KR24 p. 228); Baron notes skill levels and fine wares are sometimes assumed specialist/ceremonial, but warns against simple kitchen/table splits (S-BA26 pp. 27–29).
- **R** — Model households as broadly equal; differences should arise only from simulated circumstances (members, labour, luck), never from a hidden “wealth” score.

---

## 3. Economic process map (crafts, maintenance, exchange)

Each cell is tagged. “HH” = household, “Com” = cluster/community. Game seasons: 0 spring, 1 summer, 2 autumn, 3 “fallow”/winter (current code uses season 3 for “household maintenance”).

| Chain | Resources (source) | Transformations | Labour / time | Tools / facilities | Seasonality | Storage / loss | Who |
|---|---|---|---|---|---|---|---|
| **Clay supply** | Clay from an on-site pit (**E** feature 2005-O-05); water (**R**, existing water deliveries) | Dig → carry → stockpile (heap/pit) (**R**) | Heavy, short bursts (**R**) | Digging stick/wooden spade (**R**, unattested) | Spring–autumn digging; pre-winter stockpile (**R** ethnographic, S-BA26 pp. 32–33) | Heap freezes; weathering improves it (**R**) | HH, possibly Com pit (**R**) |
| **Temper** | Crop-processing waste — chaff, glumes, straw (**E** in weights, S-CH19 p. 295); crushed sherds from the dump (**R**, conceivable per S-KU22 p. 10) | Collect by-product at threshing/cleaning; pick sherds from dump | Low; side-effect of food work (**R**) | Baskets (**R**) | After harvest (**R**) | Kept dry (**R**) | HH (**R**) |
| **Pottery** | Clay + temper + water + fuel | Knead → coil → dry → fire (**R** method; hand-built **R**) | Skilled, part-time; storage jars hardest (**R**, S-BA26 p. 28) | Open/pit firing (**R**; no kiln **E-negative**) | Making Feb–Mar/May/July/Sept; firing from Mar/Apr (**R** ethnographic) | Vessels break → dump (**E** dump, S-KU22 pp. 5–7) | HH or a few skilled makers (**R**; Březnice unknown) |
| **Clay weights** | Clay + chaff (**E**) | Shape pyramid, mark top, fire (**E** form/marks/fired) | Low per piece; made over time by different makers (**E**, S-CH19 p. 301) | Same firing as pottery (**R**) | As pottery (**R**) | Long-lived; broken pieces to dump; withdrawn at house closure (**E**, S-KU22 p. 12) | HH (**R**) |
| **Textiles** | Wool (**R**, sheep not verified locally); flax unattested at site (**E-negative**) | Fibre prep → spin → weave (**R**) | Spinning dominates (~54% of fabric time) (**R** analogy, S-SB18 p. 364) | Spindle (whorls unverified **E-negative**); loom with weights (function debated **E**) | Spinning any season, portable; weaving indoors/winter (**R**) | Cloth wears out (**R**, unquantified) | HH (**R**) |
| **House maintenance** | Clay, chaff/straw, water, wattle rods (hazel/willow **R**), white coating (**E** exists) | Re-daub / re-plaster (≤3 layers **E**); replace sunken jar (**E** renewal) | Moderate; repeated (**R**) | — | Rods after leaf fall; daub when unfrozen (**R** ethnographic) | Plaster weathers (**R**) | HH (**R**) |
| **Timber** | Oak (construction), fir (posts), local mixed wood for fuel (**E**, S-SA22 p. 10) | Fell → trim → carry → build | Heavy; group work plausible (**R**) | Bronze axe (**R** regional), wedges (**R**) | Felling in winter/leafless season (**R**) | Posts salvaged from old house (**E** speculative, S-KU22 p. 12) | HH + Com (**R**) |
| **House life cycle** | House materials, dump | Use → salvage daub/timber → burn → dig long pit → backfill dump → closing deposit → rebuild 2–6 m or ~10 m away | Burning and pit-digging are events; rebuild is large (**R**) | Fire | Unknown | Daub/timber partly recycled, rest burned and buried (**E**, S-KU22 pp. 10–13) | Com ritual (**R**, from patterning **E**) |
| **Bronze** | Copper ingots (Alpine **E** regional), tin bronze tools/ornaments (**E** regional) | Use → wear/resharpen → break → keep as scrap or deposit (**R**); casting elsewhere (**R**) | Sharpening low; casting specialist, not at site (**R**) | Whetstone (**R**) | Exchange off-season; tool demand peaks at harvest (**R** ethnographic) | Scarce, curated; hoarded/deposited (**E** regional) | Shared/owned unclear (**R**) |
| **Salt** | Alpine salt (**R**, assumed import S-SA22 p. 3) | Arrives via exchange; consumed slowly (**R**) | None locally | Container (**R**) | Arrivals off-season (**R**) | Keeps if dry (**R**) | HH via exchange (**R**) |
| **Exchange** | Surplus grain, cloth, pots, hospitality (**R**) ↔ salt, metal, news, partners (**R**) | Visits, gifts, delayed return (**R**) | Walking ~1 h to Hvožďany (**E** distance, S-SA22 p. 5) | Paths (**R**) | Off-peak; not deep winter (**R**) | Obligations remembered, not priced (**R**) | HH-to-HH across settlements (**R**) |
| **Sharing / communal work** | Prepared food, labour | Give food to a short household; join building/harvest (**R**) | Daily/seasonal (**R**) | — | Shortage times; house-raising (**R**) | Social memory (**R**) | Com (**R**) |
| **Deposition sink** | Fine vessels, loom weights, metal | Withdrawal into long pits / hoards (**E**) | Event | — | Tied to house end (**E**) / unknown for hoards | Permanent | Com/HH (**R**) |

---

## 4. Candidate simulation functions

**Anchors used for every derivation (current code, all R).** Year = 4 seasons × 30 days = 120 days; season 3 is winter (“fallow”, current “household maintenance”). Work happens in day fraction 0.25–0.8. Existing chores: `HARVEST_TICKS` 120 per crop unit, `GRIND_TICKS` 180 per flour unit, `COOK_TICKS` 240 per batch of 48 portions; households of 4/3/3 eat one portion each per midnight, so household 0 needs 480 portions ≈ 10 cooking batches per year and households 1–2 need 360 ≈ 7.5 (`village_economy.gd`, README). One carried load (cargo 1, as grain in BV-031) is the natural abstract unit for any new bulk material. All counters must be deterministic (seed-derived if variety is wanted), conserved, saved and bounded, like BV-029/031.

> Scale warning (R): at default speed one game year is 120 × 600 s = 20 h real time. Real-world rhythms of 20–25-year houses or multi-year jar renewal are invisible unless compressed. Every “life” parameter below therefore states its real-world basis and a separate compressed game value.

### F1 — Clay digging and stockpile
- **Visible:** a villager walks to a clay pit on the settlement edge, digs, carries a load home, tips it on a small heap by the house.
- **Inputs → outputs:** labour → 1 `clay` load (cargo 1) at household heap.
- **Units / R parameters:** `CLAY_DIG_TICKS = 120` (= one harvest unit: one bounded load-producing act). `CLAY_HEAP_CAP = 6` per household (enough for one firing batch of F4 plus one re-daub of F5; capacity includes incoming commitments, as BV-031).
- **Seasonality:** dig in seasons 0–2; none in season 3 (frozen ground, R ethnographic S-BA26 pp. 32–33). Stockpile matters because winter upkeep uses autumn clay.
- **HH vs shared:** one shared pit, per-household heaps (R).
- **Depends on:** BV-031 typed transport (add `clay` type); shared pit reservation like water source queue.
- **Assets:** none existing for pit/heap; procedural R placeholder. WATER/terrain reuse.
- **Evidence:** pit **E** (2005-O-05); everything else R.
- **Observer value:** high — makes “where does the house come from” visible and introduces winter preparation.
- **Anachronism risk:** low; avoid carts and spades with metal blades.

### F2 — Crop by-product (chaff/straw) collection
- **Visible:** after grinding/cleaning grain, a villager sweeps the waste into a basket and adds it to a pile beside the house.
- **Inputs → outputs:** each processed grain unit → +1 `chaff` (side output, no extra input).
- **Units / R parameters:** 1 chaff per grain unit ground (keeps chaff ≤ processed grain, so it can never be invented); `CHAFF_CAP = 10`; collection costs 30 ticks (≈ one-sixth of a grind) so it competes with work but stays minor.
- **Seasonality:** follows grinding (year-round once grain exists).
- **HH vs shared:** household.
- **Depends on:** BV-029 grind completion hook. (If Research A's threshing/winnowing is added, attach chaff there instead.)
- **Assets:** WORK quern; basket is a placeholder (ORGANIC-001 unproduced).
- **Evidence:** **E** that unsorted crop-processing waste was collected and used as temper (S-CH19 pp. 295, 301); straw in daub is R.
- **Observer value:** medium-high — teaches recycling of waste, links food and craft loops.
- **Risk:** none notable.

### F3 — Wear, breakage and the house dump (provisional discard)
- **Visible:** occasionally a pot cracks during cooking or a bowl breaks; the sherds are carried to a growing heap beside one long wall of the house.
- **Inputs → outputs:** use events → vessel lost from household kit → +N `sherds` on household dump.
- **Units / R parameters:**
  - Household vessel kit (R, ranked on S-ZEN type frequencies — storage jar > bowl > amphora > cup > pot): 1 sunken storage jar, 1 amphora, 1 cooking pot (POT asset), 2 bowls, 1 cup.
  - Cooking pot breaks after `POT_LIFE = 5` cooking batches → household 0 loses ~2 pots/year, households 1–2 ~1.5 (derived from 10 and 7.5 batches/year above). Pure design choice; no breakage rate is attested.
  - Tableware: one bowl or cup breaks per 120 portions eaten → 4/year (household 0), 3/year (others).
  - Sunken storage jar: replaced once per compressed house life third (see F5) — reflects the nested-jar renewal (**E**, S-KU22 p. 10).
  - Each broken vessel adds 1 `sherd` unit; dump has no cap (it should visibly grow — E: dumps grew with house duration, S-KU22 pp. 10, 13).
- **Fallback:** a household with no cooking pot cannot cook (needs F4) — **must not deadlock**: allow “borrow pot” from a neighbour (F10) or cook at half rate in a substitute container (R) until a pot is made.
- **HH vs shared:** household.
- **Depends on:** BV-029 cooking/consumption events; BV-033 fuel unaffected.
- **Assets:** POT (existing), POTTERY-003 bowl/cup and STORE-001 jar (pending); a sherd heap placeholder.
- **Evidence:** dump and fragmentation **E** strong; breakage rates **R**.
- **Observer value:** high — the dump is the single best-attested Březnice “process”.
- **Risk:** avoid “durability bars” that look like modern item degradation UI; show the heap.

### F4 — Pottery and clay-weight making with batch firing
- **Visible:** a villager kneads clay with chaff or crushed sherds, coils vessels and shapes pyramidal weights indoors or by the house, leaves them to dry in a row, then builds a fire around a batch; afterwards new pots join the household kit.
- **Inputs → outputs:** `clay` + temper (`chaff` or `sherd`) + water + fuel → vessels / clay weights.
- **Units / R parameters:**
  - Per item: bowl or cup = 1 clay + 1 temper, forming 180 ticks (= one grind); cooking pot = 1 clay + 1 temper, 360 ticks; storage jar = 3 clay + 2 temper, 720 ticks and **must dry ≥ 2 days before firing** (heavy coiled walls collapse if rushed, S-BA26 p. 28); 2 clay weights = 1 clay + 1 chaff (chaff only; **E** weights tempered with processing waste), 180 ticks.
  - Water: 1 delivered water unit per 2 clay used (gives existing water deliveries their first non-drinking use; R).
  - Firing batch: up to 6 items; fuel cost 3 units (vs 1 per cooking batch in BV-033; R ratio meaning “a firing is a big fire”), 240 ticks tending. Drying: 1 day minimum for all items.
  - Winter: forming allowed; firing allowed only at double fuel (R, ethnographic: winter firing harder and fuel-hungry, S-BA26 p. 33).
  - Weights demand (R): a household loom setup wants 24 weights (most regional groups read as looms hold 14–38 weights, with Kleinklein's 107+5 an outlier, S-CH19 Table 7; Březnice mass deposits held 28 and 41 whole weights, S-CH19 p. 278). Weights last indefinitely unless withdrawn at house end (F12).
- **Seasonality:** forming any season; firing seasons 0–2 preferred (making Feb–Mar/May/July/Sept, firing from Mar/Apr in Polish ethnography — R).
- **HH vs shared:** household production by default; optional single “skilled maker” per cluster for storage jars (R, cf. two-track crafting S-BA26 pp. 25–29). Keep both as a configuration flag, not a claim.
- **Depends on:** F1, F2, F3; BV-033 fuel; BV-031 transport for clay.
- **Assets:** POT, POTTERY-003, STORE-001, LOOMWEIGHT-001 (pending), KILN-001 hearth/firewood (pending; use as fire, **not** as a pottery kiln — kilns are not attested).
- **Evidence:** vessel types, temper, fired weights **E**; method and rates **R**.
- **Observer value:** high — a full chain from ground to object.
- **Risk:** no potter's wheel, no permanent kiln building, no “workshop” or selling.

### F5 — House upkeep: re-daubing, re-plastering, jar renewal
- **Visible:** in late autumn and winter a villager mixes clay, chaff and water in a pit, presses daub into gaps, and occasionally whitewashes the wall; every few years a household digs out and resets its sunken storage jar.
- **Inputs → outputs:** 2 clay + 1 chaff + 2 water + 1 wattle bundle (F6) + 360 ticks → house `condition` +25 (cap 100). Re-plaster (white layer) increments `plaster_layers` (max 3).
- **Units / R parameters:**
  - `condition` 0–100, decays 1 per 3 days (≈ 40/yr) → about two patch jobs per year keep a house sound (R).
  - Real basis: house life 20–25 yr (**E** as model assumption, S-KU22 p. 10); ≤3 plaster layers (**E**, S-KU22 p. 10) → real re-plaster interval ~7–12 yr (R arithmetic: 20–25 yr ÷ 2–3 renewals).
  - Compressed: `HOUSE_LIFE = 8` game years (R, ≈ ×3 compression); re-plaster every 2–3 game years; after the 3rd layer, patch effectiveness halves, steering toward F12. Provide a preview setting with `HOUSE_LIFE = 2` for observation.
  - Low condition never blocks food or rest; it only raises upkeep priority and eventually triggers F12 (avoid health/happiness scores, BV-032 boundary).
- **Seasonality:** daub patching seasons 2–3 (current winter “household maintenance” slot gets real work); not when clay heap is empty.
- **HH vs shared:** household; plastering could be helped by F11.
- **Depends on:** F1, F2, F6; water deliveries; existing season-3 maintenance state.
- **Assets:** HOUSE (existing; a “patched” material variant would help), WATER.
- **Evidence:** daub, white coating, ≤3 layers, removed daub, nested jars **E**; rates **R**.
- **Observer value:** high; fills the empty winter with meaningful work (DEVELOPMENT_PLAN item 3 “household repair demand”).
- **Risk:** low.

### F6 — Wattle rods and building timber
- **Visible:** after leaf fall, villagers cut hazel/willow rods at the woodland edge and stack them; occasionally two people fell and carry an oak post.
- **Inputs → outputs:** woodland + labour (+ axe, F8) → `rods` bundle; `post` (heavy cargo needing 2 carriers).
- **Units / R parameters:** rods: 120 ticks per bundle, cap 4/household, cut only in seasons 2–3 (R ethnographic, S-BA26 pp. 39–40). Posts: 600 ticks felling per post; without an axe ×2 time (not blocked); carried as one shared load by two actors. Rebuild needs 8 posts + 6 rods (F — post count unknown; houses 5–8 m wide and oblong, S-KU22 p. 8, suggest a few paired post rows). Salvage from the old house returns up to half the posts (**E**-suggested reuse, S-KU22 p. 12).
- **Seasonality:** felling seasons 2–3 (R).
- **HH vs shared:** rods household; posts communal (F11).
- **Depends on:** BV-033 wood module (extend wood type: `fuel` vs `rods` vs `post`); F8 axe.
- **Assets:** VEG oak/hazel (existing); KILN-001 firewood pile (pending) can stand in for stacks.
- **Evidence:** oak construction, fir posts **E** (S-SA22 p. 10); forest not limiting (S-SA22 p. 10); quantities **R/F**.
- **Observer value:** medium.
- **Risk:** no sawn planks, no saws (R; not checked), no metal nails.

### F7 — Spinning and weaving
- **Visible:** a villager spins thread with a hand spindle while sitting or walking between tasks; in winter someone works at an upright frame with a row of clay weights; finished cloth is folded into the house.
- **Inputs → outputs:** `fibre` → `yarn` → `cloth`.
- **Units / R parameters:** spin 360 ticks per yarn; weave 300 ticks per yarn into cloth; 4 yarn = 1 cloth. Ratio follows the analogy that spinning is slightly more than half of fabric labour (67 of ~124 days, S-SB18 p. 364). Weaving requires the household's 24 weights (F4). Fibre: from sheep (ANIMAL-001) at 1 shearing/plucking per sheep per year (R; Soay-like yield 0.3–0.9 kg, S-SB18 pp. 360–361); before sheep exist, fibre arrives only via exchange (F9).
- **Need:** none by default. There is no evidence for cloth consumption rates; cloth is a store for gifts (F9) and closing deposits (F12). Optional F need: one cloth per household per year.
- **Seasonality:** spinning any season, preferably as low-priority idle work (never displacing food recovery); weaving seasons 3 and 0 (R).
- **HH vs shared:** household.
- **Depends on:** F4 weights; ANIMAL-001; scheduler idle slot.
- **Assets:** LOOMWEIGHT-001 (pending); spindle (SPIN-001) and loom (LOOM-001) are drafts only — weaving can be shown abstractly next to stacked weights.
- **Evidence:** weights **E**; their loom function **debated E**; flax absent **E-negative**; time ratios **R**.
- **Observer value:** medium-high, especially the “function unknown” teaching hook (show both base-down and base-up hanging as an explained uncertainty).
- **Risk:** do not show linen/flax fields; don't present the warp-weighted loom as proven.

### F8 — Bronze tool pool: use, sharpening, breakage, scrap
- **Visible:** a shared axe and two sickles hang at a fixed house; villagers fetch them for felling/harvest, return them, and sometimes sit sharpening an edge on a stone; a broken sickle goes into a small scrap bundle rather than the dump.
- **Inputs → outputs:** use → edge wear; sharpening (180 ticks) restores edge; repeated sharpening → broken → `scrap`. New tools/ingot fragments only via F9.
- **Units / R parameters:** cluster pool: 1 axe, 2 sickles (F counts; scarcity is the R point). Edge 20 uses; 10 sharpenings per tool life (R). Missing tool never blocks work: harvest/felling at half rate with “stone/wood” substitute (R).
- **Seasonality:** sharpening peaks before harvest (season 1–2) (R ethnographic, S-BA26 p. 39).
- **HH vs shared:** shared pool with “keeper” household (R; ownership is unknown — the keeper is not an owner in property-law sense).
- **Depends on:** harvest (BV-029/031), F6 felling.
- **Assets:** TOOL-001 sickle (existing per material-culture.md); BRONZE-001 axe/knife (draft, not dispatched).
- **Evidence:** regional bronze tool types and ingots **E**; local bronze only as one melted droplet **E**; no local casting **E-negative**; quantities **F/R**.
- **Observer value:** high — scarcity and curation are central Bronze Age lessons.
- **Risk:** no village smithy, no casting, no iron, no coin-like ingot values.

### F9 — Exchange visit with a neighbouring settlement
- **Visible:** after harvest, a stranger (or a villager returning from a day's walk) arrives with a bundle; the host household cooks a meal, both sides hand over gifts; the observer log reads e.g. “H2 hosted a visitor from across the river: gave 2 grain, 1 cup; received salt.”
- **Inputs → outputs:** host gives prepared portions (hospitality) + 1–3 gift items (grain, pot, cloth, weights); receives 1 item from a visit table: `salt`, copper ingot fragment, bronze tool, fibre, or nothing (only news/relationship).
- **Units / R parameters:** 1 visit per year in season 2 or 0 (R: off-peak, not winter, S-BA26 p. 39). Travel ~1 h each way to Hvožďany (**E** distance, S-SA22 p. 5) → a villager leaving is absent for one day-work window. Ledger per partner: `given`, `received` counts by item kind — never converted into a common value. Reciprocity rule (R): next visit's gift is larger if the partner gave more last time; a long-unbalanced partner stops visiting for a year.
- **Salt:** `salt` units are consumed slowly (1 per household per 60 days; F) and have no mechanical effect at first (avoid inventing nutrition effects); they explain why exchange matters.
- **HH vs shared:** a household hosts; gifts come from its own stores.
- **Depends on:** BV-029 food stores; F3/F4/F7 outputs; DEVELOPMENT_PLAN phase 4.
- **Assets:** PERSON (visitor variant), POT; bundle placeholder.
- **Evidence:** route/import **assumed** (S-SA22 p. 3); Alpine copper reaching South Bohemia **E** (S-KM20); mechanism **R**.
- **Observer value:** very high for learning (“no money, but obligations”).
- **Risk:** highest anachronism risk — no traders with stalls, no prices, no “profit”, no market day.

### F10 — Intra-cluster food sharing
- **Visible:** a villager carries a pot of prepared food to a neighbouring house whose need counter is high; the log names giver and receiver.
- **Inputs → outputs:** donor prepared portions → receiver prepared portions (physical carry, conserved).
- **Units / R parameters:** trigger when receiver `need ≥ members` (≥ one missed household day) and donor stock ≥ donor's own next 2 days + portions to give; give up to receiver's 1-day demand. Ledger `helped[a][b]`; donors preferentially help households that helped them (generalised reciprocity, R). No debt, no repayment demand.
- **HH vs shared:** inter-household; never a central pool (BV-032 boundary: household-first is a design choice).
- **Depends on:** BV-029 needs/portions; BV-031 carry interface (`food` cargo type); BV-032 overview to display transfers.
- **Evidence:** **R** only (S-SA25 suggests separate household economies; no sharing evidence either way).
- **Observer value:** very high — shows why a village survives shortages.
- **Risk:** don't call it “trade” or “loan”.

### F11 — Communal work party
- **Visible:** when a large job is due (rebuild, post hauling, big firing), adults from other households walk over and work together; the host cooks a shared meal afterwards.
- **Inputs → outputs:** labour ticks from helpers into host task; host spends portions on a meal (1 portion per helper).
- **Units / R parameters:** tasks flagged `large` accept up to 4 helpers; helpers only if their household has no unmet need and it is not their own harvest window (R). Ledger: helper-days per household pair; reciprocity bias as F10.
- **Depends on:** F5/F6/F12, scheduler priority rules, BV-029 portions.
- **Evidence:** need for collective effort plausible (tons of daub, S-KU22 p. 6); organisation **R**.
- **Observer value:** high.
- **Risk:** no wages, no hiring.

### F12 — House end and renewal (abandon, salvage, burn, long pit, closing deposit, rebuild)
- **Visible:** an old house is emptied; villagers take down reusable daub and posts; the shell is burned; later they dig a long narrow pit along the old wall line, shovel in the burnt dump, place a few intact fine bowls/cups and some loom weights on top, and fill it; a new house rises 2–6 m away.
- **Inputs → outputs:** old house + dump + selected goods + fuel + labour → recycled `clay`/`post`s, a closed long pit, new house (condition 100, plaster 0).
- **Units / R parameters:** trigger at `HOUSE_LIFE` (F5) or condition 0 after 3 plaster layers. Salvage returns ½ posts and 4 clay (R; most daub removed, S-KU22 pp. 10–11). Burning costs 6 fuel (R, “big fire”). Long pit digging 600 ticks (R). Closing deposit: 1–2 best tableware items + up to ½ of the household's weights withdrawn permanently (**E** pattern: unburned fine vessels and weights as last deposits, S-KU22 pp. 7, 12). New site offset 2–6 m (**E** spacing, S-KU22 p. 8). Household members, stores and food continue uninterrupted (live in neighbour's house during rebuild — R, needs F11).
- **Seasonality:** unknown (R: after harvest).
- **HH vs shared:** household event with communal labour (F11).
- **Depends on:** F3, F5, F6, F11; persistence of house position (new save version); HOUSE placement code.
- **Assets:** HOUSE; LONGPIT-001 (draft in settlement-features.md; not among pending PRs); fire placeholder from KILN-001.
- **Evidence:** **strongest site-specific E** (sequence and patterning); meaning/ritual **R**.
- **Observer value:** very high and unique to Březnice; also the main economic sink.
- **Risk:** don't depict a raid or catastrophe; don't call it worship (authors reject cult reading, S-KU22 p. 13).

### Functions considered and not recommended (yet)
- **Local bronze casting** — no evidence at the site; would mislead.
- **Hoard deposition by villagers** — regional E, but no hoard at Březnice; possible later as a rare F/R event tied to F8 scrap.
- **Salt production** — no local source.
- **Wealth/status score** — no local evidence; violates BV-032 boundary.

---

## 5. Ranked recommendations (top 5) — ticket drafts, proposals only

Ranking weighs: local evidence strength, observer/learning value, fit to DEVELOPMENT_PLAN phases 3–4, reuse of accepted BV-029/031/033 interfaces, and anachronism risk. None of these is dispatched; IDs are placeholders.

### 1. BV-0xx — Clay, chaff and house upkeep (F1 + F2 + F5)

Status: proposal; depends on accepted BV-031 typed transport and BV-033 wood module (rods may initially reuse the wood source). Deliver one observable clay→daub→house-condition loop that gives winter “household maintenance” real work. Villagers dig clay at one shared pit (seasons 0–2), carry single loads to a capped household heap, collect chaff as a side output of grinding, and in seasons 2–3 patch the house with clay+chaff+delivered water(+rods), raising a bounded `condition`; re-plastering increments `plaster_layers` (max 3). R rules (all labelled R in code/README): dig 120 ticks; heap cap 6; 1 chaff per ground grain unit, cap 10; patch = 2 clay + 1 chaff + 2 water (+1 rod bundle when available) for +25 condition; decay 1 per 3 days; no penalty except higher upkeep priority. Historical boundary: on-site clay pit, chaff temper, ≤3 plaster layers and removed daub are E (S-ZEN; S-CH19 pp. 295, 301; S-KU22 pp. 6, 10–11); rates, caps and decay are R; house life compression is explicit. No pottery, house replacement, exchange or new livestock in this slice. Acceptance: exact conservation of clay/chaff/water across dig, carry, store and patch (atomic multi-input consumption, as BV-033 cooking); heap capacity includes incoming loads; food recovery and harvest remain possible with empty heaps or frozen season; deterministic speed/pause; save/load mid-dig, mid-carry and mid-patch with validated migration; rendered proof of heap growth and patching; independent Standards/Spec review.

### 2. BV-0xx — Breakage, house dump and batch pottery firing (F3 + F4, weights optional)

Status: proposal; depends on #1 (clay, chaff) and BV-033 fuel. Make household vessels finite: cooking and eating wear deterministic counters, broken vessels become sherd units on a visible dump beside the house, and households replace them by forming items from clay plus temper (chaff or sherds), drying them and firing a batch with fuel. R rules: kit 1 storage jar, 1 amphora, 1 cooking pot, 2 bowls, 1 cup; pot breaks after 5 cooking batches; one tableware item per 120 portions eaten; forming 180/360/720 ticks (bowl-cup/pot/jar), jar must dry ≥2 days; batch ≤6 items, 3 fuel, double fuel in winter; optional weights 2 per clay+chaff. A household without a cooking pot borrows one (or cooks at half rate) — never a deadlock. Historical boundary: vessel types/frequency, dump/fragmentation, chaff temper and grog reuse in the region are E (S-ZEN; S-KU22 pp. 5–7, 10; S-CH19 p. 295); breakage rates, recipes, firing method and fuel are R; no kiln, wheel, workshop or sale. Acceptance: inventory conservation (clay+temper → green → fired → in-use → sherd), last-unit fuel/clay contention, no cooking deadlock under pot loss, multi-year runs without unbounded queues, dump growth visible and inspectable, save/resume mid-drying and mid-firing, BV-032 overview shows kit and dump counts with R labels.

### 3. BV-0xx — Physical food sharing between households (F10)

Status: proposal; depends on BV-029 needs and BV-031 carry interface (`food` cargo). When a household has missed at least one household-day of portions and another household holds more than its own next two days of portions, a donor carries up to one day of the receiver's demand to their house. A per-pair ledger records who helped whom and biases future helping toward past helpers. R rules: thresholds as stated; donation is physical, conserved and interruptible; no repayment, debt, interest or central pool. Historical boundary: no inspected source documents sharing at Březnice; Šálková 2025 supports household-level economies (BV-032), so household stores remain primary; mechanism is an R ethnographic-style choice. Acceptance: one-household shortage despite village surplus is resolved by actual carrying within a bounded time; no donor drops below its own threshold; ledger matches transfers; at-most-once delivery on interruption; overview (BV-032) explains giver/receiver; multi-season determinism and save/resume mid-carry.

### 4. BV-0xx — House end and renewal (F12 + F11)

Status: proposal; depends on #1–#2 (condition, plaster layers, dump, vessels) and wood posts. When a house reaches its compressed life or fails after three plaster layers, villagers salvage half the posts and some clay, burn the shell (fuel), dig a long pit along the old wall line, move the dump into it, withdraw one or two intact tableware items and part of the weights as a closing deposit, and build a new house 2–6 m away with helpers from other households who are fed by the host. Household membership and stores persist; inhabitants lodge with a neighbour during rebuilding. R rules: `HOUSE_LIFE` 8 game years (preview 2); salvage ½ posts + 4 clay; burn 6 fuel; pit 600 ticks; up to 4 helpers; meal 1 portion per helper. Historical boundary: the sequence, dump origin of fills, burning at 1,000–1,200 °C, unburned fine vessels and weights as last deposits, daub/timber reuse and pit spacing are E/E-suggested (S-KU22 pp. 6–13; S-CH19 p. 301); timing, labour and fuel amounts are R; no raid, catastrophe or cult framing. Acceptance: deterministic, saveable multi-stage event that cannot strand a household without shelter/food; materials conserved or explicitly destroyed with counters; new house placement collision-free; rendered proof of each stage; asset gap (LONGPIT-001, HOUSE variants) documented with placeholders.

### 5. BV-0xx — Exchange visits, salt and the bronze tool pool (F9 + F8)

Status: proposal; depends on #2 (gift goods) and #3 ledger pattern; independent of livestock. Once per year in autumn or spring, a visitor from a neighbouring settlement arrives (or a villager walks there for a day); the host household serves a meal and gives 1–3 items from its stores, and receives one item from a seeded table (salt, copper ingot fragment, a bronze tool, fibre, or nothing). The cluster keeps a small shared tool pool (1 axe, 2 sickles) whose edges wear with harvest/felling, are sharpened on a stone, and eventually break into scrap that is kept, not recast. R rules: one visit/year; partner ledger counts items by kind (never summed into a value); imbalance changes next gift size and can pause visits; tool edge 20 uses, 10 sharpenings; missing tools halve work speed, never block it; salt consumed slowly with no stat effect. Historical boundary: Alpine copper reaching South Bohemia and alloying in the region are E (S-KM20 abstract), Hallstatt salt mining and South Bohemian links via miner's picks are E (S-RK19; S-KR24), the Alps–Central Bohemia route past Březnice is an inherited assumption (S-SA22 p. 3); no local casting evidence; exchange mechanism and quantities are R/F; no money, prices, merchants or markets. Acceptance: conserved inventories across gifts; ledger and log readable in BV-032 overview; tool pool never deadlocks harvest; deterministic visit schedule; save/resume during a visit and with scrap/tools in stores.

**After these:** F7 textiles once ANIMAL-001 sheep exist (then F4 weights become useful); F6 posts if not already covered by #4.

---

## 6. Open questions, inaccessible sources, bibliography

### 6.1 Open questions (for a qualified archaeologist or later research)

1. Does the Březnice monograph (Chvojka, Kuna, Menšík et al. 2021) report stone-tool raw materials (quern and hammerstone sources), spindle whorls, metal finds beyond the melted droplet, or casting debris? Section “Kovové artefakty” (p. 140) not seen.
2. Was the clay pit (2005-O-05) used for daub, pottery or both? Are there petrographic studies of Březnice fabrics (grog vs mineral temper)?
3. Are the “slag-like” lumps in DTB1 vitrified ceramic/daub (our R reading) or anything metallurgical?
4. Any evidence for who made pottery at Březnice — household-level variability vs standardisation (e.g. maker “handwriting” as hinted for weights, S-CH19 p. 292)?
5. Loom weights: base-up hanging, spit supports or other use — any newer use-wear or experimental work after 2019?
6. Flax/hemp and wool: any textile impressions on Březnice pottery or daub? Any South Bohemian LBA spindle-whorl assemblages?
7. Salt: any South Bohemian LBA evidence (briquetage, isotopic/residue) beyond the route assumption?
8. Kmošek et al. 2020 full text: where in South Bohemia was copper refined and alloyed (settlement evidence)?
9. Seasonality of house burning and long-pit digging (micromorphology, Strouhalová 2021 in the monograph).
10. Household vessel use-lives: an ethnographic breakage-rate source suitable for Central European coarse ware (none read here; current numbers are pure R).

### 6.2 Sources not accessible or not inspected

- Chvojka & John 2022, Tichá hoard (CU DSpace) — request timed out.
- Kmošek et al. 2020 (AAS 12:234) — closed; abstract only.
- Kmošek et al. 2025 published version (AAS) — closed; CC BY preprint used.
- Chvojka, Kuna, Menšík et al. 2021 monograph — print only; TOC seen by Research A.
- Šálková et al. 2025 (*Archaeological Prospection*) — not re-read in this session; claims reused from existing bounded notes.
- Kyselý 2016 (*Živa*) — not inspected (outside this scope; cite-only).
- Šálková et al. 2019 “Crops along the trade routes?” (ref. 41 in S-SA22) — not inspected; source of the route assumption.
- Open-firing experiment (Hrčak 156651) — HTML only, not read.

### 6.3 Licence notes

- S-KU22 is CC BY-NC-ND 4.0: cite only; no figures/text reuse in game assets or docs.
- S-BA26 is CC BY-NC 4.0: cite; no commercial reuse of figures.
- S-CH19 (ARÚ PDF) has no explicit licence: cite only; figures not reusable.
- S-SA22, S-ZEN, S-KR24, S-KM25 preprint, S-RA19, S-MO21, S-SB18 are CC BY 4.0 (attribution required if anything is ever reused).
- No images were downloaded; `references/` contains no files from this research.

### 6.4 Bibliography

- **S-SA22** Šálková, T., Vobejda, L., Chvojka, O., Beneš, J., Vondrovský, V., Kuna, M., Křivánek, R., Menšík, P. & Novák, J. 2022. Extensive archaeobotanical data estimate carrying capacity, duration, and land use of the Late Bronze Age settlement site Březnice (Czech Republic). *Scientific Reports* 12: 20323. https://doi.org/10.1038/s41598-022-24753-x — repository PDF: https://naos-be.zcu.cz/server/api/core/bitstreams/7115b54d-fe44-4a16-9a8c-ea51b7a2400d/content.
- **S-KU22** Kuna, M., Němcová, A., Šálková, T., Menšík, P. & Chvojka, O. 2022. Deposition analysis and the hidden life of Bronze Age houses. *Journal of Anthropological Archaeology* 67: 101433. https://doi.org/10.1016/j.jaa.2022.101433 — repository PDF: https://naos-be.zcu.cz/server/api/core/bitstreams/5d93fa40-360f-4931-8205-53a35c41cb0b/content (CC BY-NC-ND 4.0).
- **S-CH19** Chvojka, O., Menšík, P., Šálková, T. & Kuna, M. 2019. Tkalcovská závaží nebo podstavce pod rožně? Hliněná závaží ze sídelního areálu z mladší doby bronzové v Březnici u Bechyně z pohledu archeologie a archeobotaniky. *Archeologické rozhledy* 71: 267–308. https://www.arup.cas.cz/wp-content/uploads/2019/11/4_Chvojka_267-308_web.pdf
- **S-ZEN** Kuna, M., Němcová, A. & Chvojka, O. 2022. Sídliště z mladší doby bronzové v Březnici (Česko): data pro depoziční analýzu — The Late Bronze Age site in Březnice (Czechia): data for deposition analysis. Zenodo. https://doi.org/10.5281/zenodo.6475797 (CC BY 4.0).
- **S-SA25** Šálková, T. et al. 2025. Waste Management and Waste Disposal … (Březnice; full title and authors per publisher). *Archaeological Prospection* 32: 525–548. https://doi.org/10.1002/arp.1973 (not re-read in this session).
- **S-MONO** Chvojka, O., Kuna, M., Menšík, P. et al. 2021. *Rituály ukončení a obnovy. Sídliště mladší doby bronzové v Březnici u Bechyně.* České Budějovice – Praha – Plzeň. ISBN 978-80-7394-899-3. TOC: https://www.muzeumcb.cz/files/files/Eshop/toc-783893-pdf.pdf (not inspected here).
- **S-KR24** Chvojka, O., Jiráň, L., John, J., Kmošek, M., Thér, R. & Zachar, T. 2024. Hoard with a miner's pick from Krtely in South Bohemia: On the question of the relations of hoards, imports and burial mounds of the Urnfield period. *Archeologické rozhledy* 76: 221–256. https://doi.org/10.35686/AR.2024.248 — PDF: https://archeologickerozhledy.cz/index.php/ar/article/download/248/260 (CC BY 4.0).
- **S-KM20** Kmošek, J., Kochergina, Y., Chvojka, O. & Fikrle, M. 2020. Tracking Alpine copper — analysis of Late Bronze Age copper ingot hoard from South Bohemia. *Archaeological and Anthropological Sciences* 12: 234. https://doi.org/10.1007/s12520-020-01186-z (closed; abstract only).
- **S-KM25** Kmošek, J., Augustýnová, M., Fikrle, M. & Erban Kochergina, Y. V. 2025. Bronze Age copper ingots from the Domažlice region compared with the Mutěnín copper ore deposit in western Bohemia (Central Europe). Preprint, Research Square, https://doi.org/10.21203/rs.3.rs-6507188/v1 (CC BY 4.0); published in *Archaeological and Anthropological Sciences* (2025), https://doi.org/10.1007/s12520-025-02355-8.
- **S-PE16** Pernicka, E., Lutz, J. & Stöllner, T. 2016. Bronze Age copper produced at Mitterberg, Austria, and its distribution. *Archaeologia Austriaca* 100: 19–55. https://doi.org/10.1553/archaeologia100s19 — PDF: https://austriaca.at/0xc1aa5576_0x00349813.pdf
- **S-RA19** Radivojević, M., Roberts, B. W., Pernicka, E., Stos-Gale, Z., Martinón-Torres, M., Rehren, T., Bray, P., Brandherm, D., Ling, J., Mei, J., Vandkilde, H., Kristiansen, K., Shennan, S. J. & Broodbank, C. 2019. The provenance, use, and circulation of metals in the European Bronze Age: The state of debate. *Journal of Archaeological Research* 27: 131–185. https://doi.org/10.1007/s10814-018-9123-9
- **S-MO21** Mödlinger, M., Trebsche, P. & Sabatini, B. 2021. Melting, smelting, and recycling: A regional study around the Late Bronze Age mining site of Prigglitz-Gasteil, Lower Austria. *PLoS ONE* 16(7): e0254096. https://doi.org/10.1371/journal.pone.0254096
- **S-RK19** Reschreiter, H. & Kowarik, K. 2019. Bronze Age mining in Hallstatt. A new picture of everyday life in the salt mines and beyond. *Archaeologia Austriaca* 103: 99–136. https://doi.org/10.1553/archaeologia103s99 — PDF: https://austriaca.at/0xc1aa5572_0x003b1206.pdf
- **S-LA24** Lane, D. 2024. Technology and risk — Bronze Age hoards as a form of risk management. *Študijné zvesti Archeologického ústavu SAV* 71(1): 89–113. https://doi.org/10.31577/szausav.2024.71.6
- **S-PO24** Pokorná, A., Kočár, P. & Šálková, T. 2024. Changes in spectra of cultivated and gathered plants in the Bronze Age: A study based on archaeobotanical data from the Czech Republic. *Archeologické rozhledy* 76: 173–188. https://doi.org/10.35686/AR.2024.223
- **S-BA26** Baron, J. 2026. *Craftwork in Small-Scale Societies of the Central European Bronze Age.* Elements in the Archaeology of Europe. Cambridge University Press. https://doi.org/10.1017/9781009611251 (CC BY-NC 4.0).
- **S-SB18** Sabatini, S., Earle, T. & Cardarelli, A. 2018. Bronze Age textile & wool economy: The case of the Terramare site of Montale, Italy. *Proceedings of the Prehistoric Society* 84: 359–385. https://doi.org/10.1017/ppr.2018.11
- **S-DO23** Doležalová, K., Řídký, J. & Pilař, D. 2023. Rhyolite grinding-milling tools in focus: Assessing kinematics with the help of use-wear analysis. *Archeologické rozhledy* 75: 109–131. https://doi.org/10.35686/AR.2023.9
- Project files: `content/research/next-batch/material-culture.md`, `content/research/next-batch/settlement-features.md`, `art/handoffs/bronze-bohemia-opus-v2/references/research-notes.md`, `team/tasks/BV-029.md`, `BV-031.md`, `BV-032.md`, `BV-033.md`, `DEVELOPMENT_PLAN.md`.
