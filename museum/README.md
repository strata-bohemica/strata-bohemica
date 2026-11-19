# Museum (Godot 4.5.1, GL Compatibility)

A digital open-air museum of Bohemian prehistory. M3: a village on uneven ground with ten homesteads (grinding, cooking, weaving, woodworking, spinning, parching, threshing, hide scraping, milking, daub treading), animals, trees and hearth smoke, working from dawn to night. The plough and the potter's house stand empty until their research and models are settled.
Everything the scene does is a pure function of time; the view only applies it.

```
core/    day clock, craft timeline, craft props, animals, schedule, terrain, schema   (no nodes, testable headless)
data/    period, crafts, homesteads, village + terrain, asset catalogue      (JSON, shared with the web page)
assets/  catalogue: "WORK-001/person_grinding" -> path, clips, anchors
view/    thin Godot adapters: pose driver, homestead view, terrain view, village view
app/     the main scene and the loader that assembles the village
```

Adding a craft or a homestead means adding JSON, not code. Animals are data too: a cycle of clips whose length divides the day. Models are referred to by asset ID, never by path.

## Run

```sh
godot --path .      # Space pause, Q/W/E speed, 0 overview, 1-4 homestead, Tab next, L cutaway, right-drag orbit, wheel zoom
checks/museum_village/run.sh                     # core, data, terrain, boundary and view checks (headless)
```

## The village

The village layout and the ground are **F/R**: no house plan or terrain model of Březnice survives. `tools/organic_layout.py`
chose the house positions on a fictional height field (seed 11); `tools/build_village.py` levels a platform under each house and
work yard, routes the paths over the terrain and writes `data/villages/breznice*.json`.
A craft lists its props in data: placed on a station anchor, on a node of the worker or of another prop, held in a hand
node during named clips, or resting where it is put down (`core/craft_props.gd`).

## Assets

`tools/sync_assets.py FACTORY_RETURNS_DIR` copies the assets listed in `data/asset_manifest.json` into `assets/`
and regenerates `data/assets.json`. `tools/import_settings.py` then sets the import options the models need
(`gltf/naming_version=2`, textures kept inside the scene, animation optimizer off); the generated `.import` files are committed, the PNGs Godot would extract are not.

## Evidence

Every craft carries a card with an evidence class (E observed, R reconstruction, F fiction), what is unknown and its sources.
The day rhythm and the layout of the work place are F. No house plan survives at Březnice; the layout is reconstruction.

Licence: code MIT (`../LICENSE`), models, textures and animations CC BY 4.0 (`../LICENSE-ASSETS.md`).
