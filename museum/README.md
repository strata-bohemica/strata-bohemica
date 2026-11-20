# Museum (Godot 4.5.1, GL Compatibility)

A digital open-air museum of Bohemian prehistory. M6: the plougher walks a real path to a field and ploughs up and down it with two oxen; ten more homesteads work in their yards. M4: click a person to read how well their craft is supported (evidence, reconstruction, what is unknown, sources), in Czech or English. Behind it, a village on uneven ground with ten homesteads (grinding, cooking, weaving, woodworking, spinning, parching, threshing, hide scraping, milking, daub treading), animals, trees and hearth smoke, working from dawn to night. The plough and the potter's house stand empty until their research and models are settled.
Everything the scene does is a pure function of time; the view only applies it.

```
core/    day clock, soundscape, craft timeline, craft props, animals, travel, schedule, terrain, card, i18n, picking, schema   (no nodes, testable headless)
data/    period, crafts, homesteads, village + terrain, asset catalogue      (JSON, shared with the web page)
assets/  catalogue: "WORK-001/person_grinding" -> path, clips, anchors
view/    thin Godot adapters: sound, pose driver, homestead view, terrain view, village view
ui/      card panel and time bar (they draw what core/card.gd and the app give them)
app/     the main scene and the loader that assembles the village
```

A person who moves while working (the plough) is a pure function of the time they have worked: `core/travel.gd` walks a line,
turns round and walks back; the schedule keeps their place through the meal and walks them home from wherever they stopped,
after a commute along the least-cost path from the yard to the field (`tools/build_village.py` writes it as `sites`).
Adding a craft or a homestead means adding JSON, not code. Animals are data too: a cycle of clips whose length divides the day. Models are referred to by asset ID, never by path.

## Run

```sh
godot --path .      # click a person for the card; M mute, Space pause, Q/W/E speed, 0/Esc overview, 1-9 homestead, Tab next,
                    # F follow, L cutaway, C language (cs/en), right-drag orbit, wheel zoom; slider scrubs the day
checks/museum_village/run.sh                     # core, data, terrain, boundary and view checks (headless)
```

## The village

The village layout and the ground are **F/R**: no house plan or terrain model of Březnice survives. `tools/organic_layout.py`
chose the house positions on a fictional height field (seed 11); `tools/build_village.py` levels a platform under each house and
work yard, routes the paths over the terrain and writes `data/villages/breznice*.json`.
Two house types alternate (`house_types` in `data/villages/breznice-layout.json`: odd houses type A, HOUSE-004, 15 × 5.5 m, three rooms;
even houses type B, HOUSE-005, about 8.5 × 5 m, one room), in plain, limewashed or patterned daub; both are R/F reconstructions after
other Bohemian sites, not plans of Březnice houses.
The fields carry furrows (SB-008): `data/villages/breznice-furrows.json` (written by `tools/build_furrows.py`) gives each field a direction and a
depth, width and spacing inside the ranges measured with a replica of Walle-type ards from Opava (Kováčik et al. 2022: 8–12 cm, 4–6 cm, 18–35 cm; evidence R, a regional
analogy; no ard or furrow is attested at Březnice). `view/furrows.gdshader` draws them from world position on one flat patch per field: no instances,
no texture, and they fade out when the groove is narrower than ~1.5-3 screen pixels, so they show only when you zoom in (within about 15 m). The patch carries the ground's own colour, so a field looks the same as before wherever the pattern has faded.
A craft lists its props in data: placed on a station anchor, on a node of the worker or of another prop, held in a hand
node during named clips, or resting where it is put down (`core/craft_props.gd`).

## Web build

`export_presets.cfg` has a single-threaded Web preset (no special server headers needed). `.github/workflows/pages.yml` exports it in a
`barichello/godot-ci:4.5.1` container and publishes it at `/museum/` next to the diorama page. Locally:

```sh
godot --headless --import
godot --headless --export-release "Web" build/web/index.html     # needs the 4.5.1 export templates
python3 -m http.server -d build/web 8000
```

The first load is about 30 MB of engine and 30 MB of data. The UI scales to the screen density and re-flows on a phone (the card
becomes a sheet along the bottom); touch: tap to select, drag to orbit, two fingers to zoom.

## Sound (foundation, SB-018)

No recordings are shipped yet; this is the frame the ambient, spatial and craft sounds (SB-019..021) plug into.

- `core/soundscape.gd`: pure functions of time. `layers(t, season, weather, day_length)` gives the loudness 0..1 of `dawn`, `day`, `dusk`, `night`, `wind`
  (season 0 winter..1 summer and weather 0..1 are placeholders, defaults summer/clear, until SB-016/SB-015). `events(kinds, t0, t1, ...)` plans the
  random one-shots (bird call, dog bark; kinds in `data/sound.json`) from a stateless hash of (kind, time bucket of the day): same window, same events,
  independent of how the window is cut, repeating every day (this needs every `bucket_s` to divide the period's `day_length_s`, 360 s today; `test_sound.gd` checks both, and its `DAY` equals the period's day). No random generator, no state, so scrubbing the slider keeps the scene a function of time.
- `view/sound_view.gd`: creates the buses `Ambient`, `Sources` (3D sources), `Craft`, `UI` under `Master` (offsets in `data/sound.json`), keeps volume and
  mute, eases gains (starts silent and fades in; default volume 0.5 = -12 dB), ducks the scene buses while paused and silences everything, immediately (no fade), when the window/tab loses focus (it fades back in on return), and emits `one_shot` for events of the elapsed frame (not when scrubbing, running backwards or faster than x10).
  `levels` holds the current layer loudness for SB-019 to mix. The choice is stored in `user://sound.cfg` (`ConfigFile`; a failed load or save is
  ignored and the session just keeps the choice). Controls: "Sound" button and a volume slider in the bottom bar, key `M`. On a phone (narrow layout) the bar shows only a mute button, a speaker icon of
  the same width muted or not, and no volume slider; volume there is the device's own. Whether that satisfies "volume/mute on mobile" is an open choice for the owner.
  A phone bar must keep the day slider at 48 px or more and stay inside a 360 px screen in Czech and English (`test_ui.gd`).
- The only audio asset is a 0.25 s test tone generated by script (`SoundView.make_tone`, 11 kB in memory, not in the pck), played on the `UI` bus when the slider is released.

### Unlocking audio on the web

Browsers may keep an `AudioContext` suspended until the user acts on the page (MDN: "Create or resume context from inside a user gesture",
<https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API/Best_practices>). Godot 4.5 handles this itself, so no entry button is needed:

- The Web export plays audio through the Web Audio API as *samples* by default (no AudioEffects, no reverb/doppler, no procedural streams such as
  `AudioStreamGenerator`; positional audio "may not always work correctly"), and the manual says "The easiest way around this limitation is to request the player
  to click, tap or press a key/button to enable audio"
  (<https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html>).
- The engine resumes the context after input: `DisplayServerWeb` calls `OS_Web::resume_audio()` ("Resume audio context after input in case autoplay was denied") in the key,
  mouse-button, touch start/end and IME callbacks, not on mouse move, wheel or touch move
  (<https://github.com/godotengine/godot/blob/4.5.1-stable/platform/web/display_server_web.cpp>); `godot_audio_resume` calls `ctx.resume()` only while the state is not `running`
  (<https://github.com/godotengine/godot/blob/4.5.1-stable/platform/web/js/libs/library_godot_audio.js>).
- Decision (smallest variant): the first click, tap or key press of a normal visit (selecting a house, orbiting, Space) is the unlock gesture. No entry screen, no extra download.
  Until then the page is simply silent (and the volume fades in once it runs). Scrolling or moving the mouse alone does not unlock.
- What is robust: the engine's source resumes a suspended context on a key press, mouse button or touch start/end (above). The state right after load depends on the browser and
  its autoplay settings (site engagement, previous visits, flags), so no rule is claimed. Observations only: the author saw `suspended` after load and after a mouse wheel, `running`
  after one click (Chromium 155, Playwright, default policy); the independent reviewer saw `running` right after load in Chromium 155 (also with the stricter autoplay flag). Both are single
  environments; neither confirms nor refutes the other. Blurring the canvas/window sets the background flag (and releases it on focus).
- Open risk: a real hidden browser tab was never tested (Playwright kept `visibilityState` visible; only canvas/window blur was simulated). The browser pauses the project in a hidden tab,
  so the code silences Master immediately on focus loss instead of fading over frames; that this silences real output in a hidden tab is unverified. Check it before SB-019 ships loops.
  Not checked either: Safari/iOS, Firefox, touch devices, real hearing of output. Any window focus loss on the desktop (not only a hidden tab) also silences the museum.
- For the next cards: recordings must be Ogg Vorbis/WAV `AudioStream`s played as samples; do not rely on bus effects (low-pass for distance, reverb) or on `AudioStreamGenerator` on the web. Test positional sources in the web build.

### Size and CPU budget

Proposal: all sounds together at most 4 MB in the pck (Ogg Vorbis, mono for 3D sources, 30..60 s loops, quality about 3..4), which is about 45% of today's pck and about 6% of the 60 MB first load.
Measured on this change (local Web export with the 4.5.1 templates, same engine, `index.wasm` byte-identical): `index.pck` 8,658,052 B on `main` `38a616c` vs 8,669,276 B with this change (+11,224 B).
The pck packs this README, so the figure moves by a few bytes whenever the README changes; this one is for the commit that contains this text with its figures (checked equal to the CI Pages build log of that commit, which prints `du` for `index.pck`).
CPU: `sound.apply` (layers, one-shot plan, gains) takes about 14 us per frame in native desktop Godot 4.5.1 (x86, headless, 60,000 frames), 0.1% of a 60 fps frame; sample mixing itself runs in the browser's audio thread.
Not measured: wasm or phone CPU, battery, decode time of real recordings, the cost of many simultaneous samples (reference device is SB-009).

## Assets

`tools/refresh_assets.sh FACTORY_RETURNS_DIR` runs the whole refresh (sync, import, import settings, drop extracted PNGs, re-import).
`tools/sync_assets.py FACTORY_RETURNS_DIR` alone copies the assets listed in `data/asset_manifest.json` into `assets/`
and regenerates `data/assets.json`. `tools/import_settings.py` then sets the import options the models need
(`gltf/naming_version=2`, textures kept inside the scene, animation optimizer off); the generated `.import` files are committed, the PNGs Godot would extract are not.

## Evidence

The card is built from the craft's data (`museum/data/crafts/*.json`): an E/R/F status, evidence entries each with their own class,
the reconstruction, what is unknown and the sources, in both languages.

Every craft carries a card with an evidence class (E observed, R reconstruction, F fiction), what is unknown and its sources.
The day rhythm and the layout of the work place are F. No house plan survives at Březnice; the layout is reconstruction.

Licence: code MIT (`../LICENSE`), models, textures and animations CC BY 4.0 (`../LICENSE-ASSETS.md`).
