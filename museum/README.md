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

This is the frame the ambient, spatial and craft sounds (SB-019..021) plug into. No recordings are shipped yet: the ambient layer is made by script (see Ambient below).

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

### Ambient (SB-019): loops rendered by script

Atmosphere (F): the sound of the landscape is a synthetic stand-in for how a place like this might have sounded (birds at dawn, wind and insects by day, a quiet dusk, crickets at night), not a reconstruction of Bronze Age sound; no voices, no modern sounds.
All five layers are provisional until recordings replace them (SB-022). Nobody has listened to them yet: the checks below are numbers, not hearing.

- Layers (`ambient.layers` in `data/sound.json`): `dawn` (bird chorus), `day` (leaf rustle, insects), `dusk` (soft evening), `night` (crickets, distant low noise), `wind` (always, louder in a storm). Their loudness over time is the pure `Soundscape.layers(t, season, weather, day_length)`, unchanged; `SoundView` eases every layer's gain towards it (time constant `fade_tau_s`, 0.4 s) so scrubbing the time slider crossfades instead of jumping, and multiplies it by `Soundscape.proximity(camera distance)`: the ambient falls to 30% when the camera is within 12 m of what it looks at and is full beyond 90 m (SB-020 sources will take over close up).
- Rendering (`core/ambient_synth.gd`): mono, 22.05 kHz, 6 s per loop (`length_s`), from a recipe and the seed `ambient.seed`; no engine random generator (integer noise), so the same data gives the same samples. It runs in slices of about 3 ms per frame (`budget_us`) after start, wind first; a layer is ready when both its copies (below) are rendered. Filtered noise is cross-faded end into start; cricket and insect voices use whole cycles per loop and bird chirps wrap around, so the end runs into the start with no step in value or slope. Generated sound adds nothing to the pck.
- Two copies per layer (`overlap`), from two seeds: each loop has a sin fade baked in (`_run_apply`) and a second player starts half a loop later, so the two windows add to constant power. Reason, from the engine source: on the web a looping sample is restarted from the `ended` event and always from the offset it was started at, not sample-accurately (see below); the fade hides the short gap under the other copy. Desktop loops are gapless either way. The second copy is rendered from another seed (`AmbientBank.COPY_SEED_STEP`; the seed also moves the phase of phrases, pulses, carriers and gusts): two copies of one rendering half a loop apart would add to a signal that repeats after half a loop (measured: 4 s instead of 8 s).
- Period (measured, `test_ambient.gd`): the correlation of the 50 ms loudness envelope of the playing pair with itself, over 20 s: at half a loop (3 s) wind 0.03, day 0.32, dusk -0.04, night 0.29, dawn -0.05 (the guard is below 0.6); at a whole loop (6 s) 0.99 to 1.00. With both copies from one seed it is 0.99 to 1.00 at half a loop. So each layer repeats after its 6 s loop, not sooner; that is still a short loop (the same bird phrase returns every 6 s): a listening and design question for the owner, and a reason to replace the layers with longer recordings (SB-022). Where the day's tonal voices (crickets) have a fixed rhythm, that rhythm is audible by nature.
- Only audible layers have players: a layer gets players (and, on the web, its browser buffers) when its loudness is above 0.02 and loses them when its eased gain is below 0.004 (-48 dB; hysteresis, no clicks: tested with the time slider jumping and with a run through a whole day, and each mutant failing). At most four layers have players at once (during a crossfade), usually two. The web engine (4.5.1) registers a stream's buffer at its first play and `unregister_stream_as_sample` is not scriptable, so streams stay registered once heard: the saving is in the copies made for playing, not in the stored buffers.
- Swapping a layer for a recording: put the file under `museum/assets/sound/` (mono Ogg Vorbis or WAV; the editor or `godot --import` imports it), set `"source": "file", "path": "res://museum/assets/sound/<id>.ogg"` on the layer in `data/sound.json` and set `gain_db`; `overlap` is ignored for a recording (one player, no baked fade). Keep the `recipe` of the layer: it is the fallback. If the file is missing or not an audio stream the layer uses its generator recipe and `push_warning`s (`AmbientBank` result `warning`), never a silent gap. Add the recording to `THIRD_PARTY.md` with its licence and listen to all of it before accepting it. What is checked and what is not:
  - A recording plays: `SoundView` gives a `file` layer a player like any other when it is audible (checked in `test_ambient.gd` with a real WAV and a real Ogg from `checks/museum_village/fixtures/`, imported by the engine: the player exists, plays, loops and has the volume of the eased gain plus `gain_db`; the mutant that starts only generated layers fails). Not checked on the web: no recording is shipped, so a recording was never played in the browser build.
  - Loop: the engine imports Ogg with `loop` off and WAV with `edit/loop_mode` disabled, so the recording would play once and fall silent. `AmbientBank.ensure_loop` switches the loop on in code (Ogg and MP3 `loop`, WAV loop forward over all frames) and reports `loop` = `set`, `on` or `unknown`; a stream type it cannot loop gets a `push_warning` (it may play once and stop). For a WAV with its own loop points (`loop_mode` already on) they are kept. Do not rely on the import flags.
  - Web, a recording restarts with a gap: it has no baked fade and no second copy, and the browser restarts a looping sample from the `ended` event: measured on the generated loops, the next pass started 0 to 53 ms after the nominal end, unmasked for a recording (a dropout or click each pass; make the recording loop at a quiet point, or accept it). Desktop loops are gapless.
  - Web, memory: the browser keeps the stereo float buffer of the recording (`seconds x 48,000 x 8` bytes: 10 s 3.8 MB, 30 s 11.5 MB, 60 s 23 MB), a second copy of it while it plays, and a third briefly at each restart (each restart copies the buffer): 30 s costs 23 to 35 MB, 60 s 46 to 69 MB, per recording. Prefer short recordings (10 to 20 s) for the web build, and count the layers that sound at once.
- Checks: `checks/museum_village/test_ambient.gd` (range, determinism, sliced equals whole, seam value and slope for both seeds, loudness across the seam, no dead air, band shares of the spectra, the fade of the bytes the players get, tonal seams (voices repeat exactly with the loop, bird chirps wrap), the period of the pair, fallback with warning, recordings (WAV and Ogg through the view), layers coming and going without clicks, scrubbing steps, camera distance), each guard with a mutant that must fail.
- Web facts, each read in the 4.5.1 sources: `AudioStreamWAV` plays as a sample (<https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html>: samples by default since 4.3, "AudioEffects are not supported"). `AudioDriverWeb::register_sample` mixes the whole stream to stereo float32 at the browser's rate (usually 48 kHz), so a loop costs about `seconds x 48,000 x 8` bytes in the browser (6 s: 2.3 MB), however small the 16-bit mono source (<https://github.com/godotengine/godot/blob/4.5.1-stable/platform/web/audio_driver_web.cpp>). `Sample.getAudioBuffer()` returns a copy of the stored buffer (`_duplicateAudioBuffer`), made at every play and every loop restart (`library_godot_audio.js`). `loop_begin` and `loop_end` are stored but not used by the browser side: the whole buffer loops, and the loop is a restart on the `ended` event (`_addEndedListener`, `_restart`), which starts at the original `offset`: so never start a looping player at a position other than 0 on the web.

- Measured (this change; numbers, not hearing): CI artifact (Pages build) in headed Chromium 1243 via Playwright, 100 s, the time speed set to x10 once the layers were ready, live `AudioBuffer`s counted after a forced garbage collection (all buffers created through `AudioContext.createBuffer`):

  | | before (8 s loops, five layers always playing) | after (6 s loops, audible layers only, two seeds) |
  |---|---|---|
  | live buffers | 15 to 17, 2.93 MB each | 14 to 18, 2.20 MB each |
  | live browser audio memory | 43.9 to 49.8 MB | 30.8 to 39.6 MB (33 MB typical) |
  | `createBuffer` calls in 100 s (copies made at play and loop restart) | 123, 360 MB allocated | 98, 215 MB allocated |

  The formula behind it: a layer that has been heard costs 2 stored buffers (one per copy); one that is playing costs 2 more, plus a transient one at each restart; so two sounding layers after a whole day are 10 stored + 4 playing. Before it was 5 stored + 10 playing. Not changed by this: stereo float at 48 kHz in the browser, whatever the source (16 kHz would not help the browser buffers). Native desktop: rendering the ten loops (five layers, two copies) takes about 1.3 to 1.9 s of work, spread over about 450 frames at 3 ms per frame; in the web build 2.2 s of work in about 15 s of wall time (the wind, then the layer of the current time of day, first), against 2.6 s in 18 s for the build before (same machine, run one after the other); no console error, 6 starts of players at the beginning and about 0.9 loop restarts per second afterwards. `sound.apply` costs a few tens of microseconds per frame natively; sample mixing runs in the browser. Restart gaps were measured on the build before, from `AudioContext.currentTime`: 0 to 32 ms (0 to 53 ms in the independent review), hidden by the baked fade; this build keeps the design and was not measured again. Not measured: phone, Firefox, Safari, battery, the hidden tab (SB-034), and anything heard.

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
