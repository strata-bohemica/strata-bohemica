# Roadmap

This page lists what the museum already shows, what we are considering next and what we have left out on purpose. It promises no dates. Everything under "Being considered" may change or be dropped. All reconstructions stay provisional.

[Česky níže](#česky)

## Done: Březnice 1.0

A Late Bronze Age village after Březnice u Bechyně (about 1150–1000 BCE), in the browser and as a Godot 4.5 project.

- **Twelve homesteads, each with a craft at work from dawn to night:** ploughing with an ox team, spinning, grinding, weaving, woodworking, cooking, milking, parching, threshing, hide scraping, daub treading, and the potter forming a bowl by hand. The pottery is an experimental variant and is not fired.
- **Evidence cards in Czech and English.** Click a person or a house to read what is attested (E), what is our reconstruction (R) and what is our free choice (F), with sources and an explicit list of what is unknown. The cards for all twelve crafts have been checked against the cited sources, and the research notes they cite are in [`research/`](research/).
- **Find details:** a loom-weight viewer on the weaving card (the whole weight and a close view of its hole), and a card for the storage-jar find from feature 6/05 with an illustrated section.
- **Fields and houses:** irregular furrows within the ranges measured in a ploughing experiment with replica ards, and two house types in three finishes with traces of hand work. Both are reconstructions after other Bohemian sites, not plans of Březnice.
- **Sound:** a generated landscape soundscape that follows the time of day, with volume and mute controls that also work on phones.
- **Viewing:** overview and follow camera, time bar, phone layout, keyboard and touch controls.
- **Checks:** headless tests run on every pull request.

## Being considered

- **Village layout:** check the layout of the twelve homesteads against the published estimate of the site's carrying capacity, and recompute it if needed.
- **Weather, seasons and lighting:** rain, fog, snow and wind; the change of seasons; light from fires, dusk and night. Each must still fit a small web build.
- **More sound:** sounds placed in the scene (water, fire, animals) and craft sounds in time with the work. Where the recordings come from and under what licence is not decided yet.
- **Models and animations:** a carpentry gesture, a daub-plastering clip, and a cow with an udder for milking. Also two checks against the sources: the ard's shape compared with the Walle-type ards from Opava, and a shorter distaff or wool held in the hand for spinning.
- **Review:** checking the site on real devices and an expert review of the Czech texts.

## Out of scope for now

- **Pottery firing:** deferred. The potter forms the bowl, but no firing scene is planned until better evidence supports one.
- **A 3D storage pit cut into the terrain:** the storage jar stays a find card with an illustrated section.
- **Homestead names** ("The plougher", "The cook" and so on) are our choice (F), not names known from the site.
- **Known limitation:** the potter's body shifts by about 10 cm twice a day when the work ends mid-cycle. We accepted this rather than change the shared work timing.

---

## Česky

Co muzeum už ukazuje, co zvažujeme a co jsme vědomě vynechali. Bez termínů. Vše v části „Zvažujeme“ se může změnit nebo vypadnout. Všechny rekonstrukce jsou předběžné.

### Hotovo: Březnice 1.0

Vesnice mladší a pozdní doby bronzové podle Březnice u Bechyně (asi 1150–1000 př. n. l.), v prohlížeči i jako projekt Godot 4.5.

- **Dvanáct usedlostí, každá s řemeslem od úsvitu do noci:** orba se spřežením volů, předení, mletí, tkaní, opracování dřeva, vaření, dojení, pražení, mlácení, škrabání kůže, šlapání mazanice a hrnčířka, která ručně tvaruje misku. Hrnčířství je pokusná varianta bez výpalu.
- **Karty s doklady česky a anglicky.** Klik na postavu nebo dům ukáže, co je doloženo (E), co je naše rekonstrukce (R) a co naše volba (F), s prameny a výslovným seznamem toho, co nevíme. Karty všech dvanácti řemesel jsou ověřené proti citovaným pramenům a výzkumné poznámky, na které odkazují, jsou v [`research/`](research/).
- **Detaily nálezů:** prohlížeč tkalcovského závaží na kartě tkaní (celek a detail otvoru) a karta nálezu zásobnice z objektu 6/05 s ilustrací řezu.
- **Pole a domy:** nepravidelné brázdy v rozsazích naměřených při pokusné orbě replikami rádel a dva typy domů ve třech úpravách se stopami ruční práce. Obojí je rekonstrukce podle jiných českých lokalit, ne plány z Březnice.
- **Zvuk:** generovaný zvuk krajiny podle denní doby, hlasitost a ztlumení i na telefonu.
- **Prohlížení:** přehledová a sledovací kamera, časová osa, rozložení pro telefon, ovládání klávesnicí i dotykem.
- **Kontroly:** automatické testy běží u každého pull requestu.

### Zvažujeme

- **Rozložení vesnice:** ověřit rozmístění dvanácti usedlostí proti publikovanému odhadu kapacity území a případně ho přepočítat.
- **Počasí, roční období a osvětlení:** déšť, mlha, sníh a vítr, střídání ročních období, světlo ohňů, soumrak a noc, vše v mezích malého webového buildu.
- **Další zvuk:** zvuky v prostoru (voda, oheň, zvířata) a zvuky řemesel v rytmu práce. Odkud nahrávky budou a pod jakou licencí, zatím není rozhodnuto.
- **Modely a animace:** tesařské gesto, nanášení mazanice a kráva s vemenem pro dojení. K tomu dvě kontroly proti pramenům: tvar rádla oproti rádlům typu Walle z Opavy a kratší přeslice nebo vlna v ruce při předení.
- **Kontrola:** ověření webu na skutečných zařízeních a odborná kontrola českých textů.

### Zatím mimo rozsah

- **Výpal keramiky:** odložen. Hrnčířka misku tvaruje, scéna výpalu se nechystá, dokud ji nepodpoří lepší doklady.
- **3D zásobní jáma v řezu terénem:** zásobnice zůstává kartou nálezu s ilustrací řezu.
- **Jména usedlostí** („Oráč“, „Kuchařka“ a další) jsou naše volba (F), ne jména známá z lokality.
- **Známé omezení:** tělo hrnčířky se dvakrát denně posune asi o 10 cm, když práce skončí uprostřed cyklu. Přijali jsme to, místo abychom měnili společné časování práce.
