# Strata Bohemica museum: guide for agents and contributors

A Godot 4.5.1 (GL Compatibility) digital open-air museum of Bohemian prehistory: Late Bronze Age Březnice u Bechyně, ~1150–1000 BCE, twelve homesteads. Planning and the backlog live in a separate private studio repo; this repo holds results only. Do not add private paths, tokens or internal task text here.

## Layout
- `museum/`: Godot code (`core/` time and state, `view/` 3D scene, `ui/`, `app/` entry) and JSON data (`data/`: crafts, homesteads, periods, villages, i18n). See `museum/README.md`.
- `assets/`: 3D models (glTF). Textures are extracted on import and git-ignored.
- `research/`: verified research notes cited by the craft cards.
- `checks/museum_village/`: headless tests.
- `site/`: three.js diorama; `export_presets.cfg` + `.github/workflows/pages.yml`: web build and deploy.
- `docs/brand/`: brand assets.

## Build and test
Needs Godot 4.5.1 stable (standard). Set `GODOT` to the binary (or put `godot` on PATH):

```sh
checks/museum_village/run.sh            # all: core epoch data terrain boundary view plough_team ui sound ambient camera object_view weather lighting
checks/museum_village/run.sh data ui    # selected
```

Run it before every PR and read the output (a missing engine fails silently). For new behaviour add a test and show it fails when the guarded code is broken.

## Rules
- The state of the village is a pure function of time. Keep it that way.
- Every reconstruction carries an evidence class and cites sources. Do not change E/R/F labels unless the cited source was actually read. Every `research/*.md` path cited in data must exist (tested).
- Content is data in JSON, UI text in `museum/data/i18n/{en,cs}.json` (both languages).
- One writer per worktree; small PRs with the `Summary / Evidence / Merge Danger` body. The owner merges.
- Licences: code MIT; models, textures, animations, renders and research CC BY 4.0; name and logo reserved. New third-party material goes in `THIRD_PARTY.md`.
- Web export is single-threaded; keep the transfer small (WebP textures, mipmaps off). The Pages workflow builds on PRs: read it before merging.
