# Jak spustit kontroly muzea

## Co je potřeba

- Godot 4.5.1 stable (standard). Kontroly běží headless, bez okna.
- Cesta k enginu: proměnná `GODOT`, jinak `.runs/tools/Godot_v4.5.1-stable_linux.x86_64`
  v repozitáři, jinak `godot` v `PATH`.

## Lokální spuštění

```sh
checks/museum_village/run.sh            # všechny kontroly
checks/museum_village/run.sh data ui    # vybrané kontroly
```

- Výchozí sada: `core data terrain boundary view plough_team ui sound ambient camera`.
- Každá kontrola je soubor `checks/museum_village/test_<jméno>.gd`.
- Skript nejdřív dvakrát spustí import projektu (první průchod rozbalí textury
  modelů, druhý je použije ve scénách), pak spustí každou kontrolu s limitem 120 s.
- Uživatelské adresáře Godotu jsou dočasné a po doběhu se smažou.
- Výstup je třeba přečíst: při selhání kontroly skript vypíše `exit N from test_<jméno>`
  na chybový výstup a skončí nenulovým kódem.

## Kontroly v CI

- `museum-tests` (`.github/workflows/checks.yml`): v kontejneru
  `barichello/godot-ci:4.5.1` spustí celé `checks/museum_village/run.sh`. Běží na
  pull requestech a na `main`, pokud se změnily cesty `museum/`, `checks/`, `tools/`,
  `assets/`, `research/`, `project.godot` nebo samotné workflow.
- `build` (`.github/workflows/pages.yml`): webový export Godotu ("Web"). Na pull
  requestech se jen sestaví, nasazuje se pouze mimo pull requesty.
- Podle komentáře ve `pages.yml` je pro `main` povinná jen kontrola `museum-tests`.
