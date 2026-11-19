# Museum (Godot 4.5.1, GL Compatibility)

A digital open-air museum of Bohemian prehistory. M1: one homestead from before dawn to night.
Everything the scene does is a pure function of time; the view only applies it.

```
core/    day clock, craft timeline, schedule, schema validation   (no nodes, testable headless)
data/    periods, crafts, homesteads, asset catalogue              (JSON, shared with the web page)
assets/  catalogue: "WORK-001/person_grinding" -> path, clips, anchors
view/    thin Godot adapters (pose driver, homestead view)
app/     the main scene
```

Adding a craft or a homestead means adding JSON, not code. Models are referred to by asset ID, never by path.

## Run

```sh
godot --path .                                   # keys: Space pause, 1/2/3 speed, L cutaway, Home reset, right-drag orbit
checks/museum_village/run.sh                     # core, data, boundary and view checks (headless)
```

## Assets

`tools/sync_assets.py FACTORY_RETURNS_DIR` copies the assets listed in `data/asset_manifest.json` into `assets/`
and regenerates `data/assets.json`. `tools/import_settings.py` then sets the import options the models need
(`gltf/naming_version=2`, animation optimizer off); the generated `.import` files are committed.

## Evidence

Every craft carries a card with an evidence class (E observed, R reconstruction, F fiction), what is unknown and its sources.
The day rhythm and the layout of the work place are F. No house plan survives at Březnice; the layout is reconstruction.

Licence: not yet chosen. Until a licence is added, all rights are reserved.
