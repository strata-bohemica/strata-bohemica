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
The plough team (yoke and oxen) is tied to the ploughman, not to the plough: the turn clips swing the plough aside and tip it about 58 degrees, so the team keeps its place in his frame and stands on the ground under each ox, leaning to the slope (at most 20 degrees; `HomesteadView._team_pose`, checked in `test_plough_team.gd`).
The team has its own frame in the schedule state (`team`: position, heading, walking): the ploughman's while he works or eats; the line start before the day's work; and after it the team turns, walks back to the line start and turns to face along the line (`Schedule._team_going_home`, 3 s per half turn, 0.6 m/s; our choice, class F). So it rests at the line start through the night and starts the next day's work where it stands. Before SB-042 it was posed from the worker skin, which stops updating after work: the oxen stood where the ploughman had stopped all night and jumped 5.93 m at the start of work every day from day 2 (19.95 m on the first day).
While the team walks the plough stays hitched: the ard is pitched about the ploughman's grip so its hitch meets the yoke's on the ground (`HomesteadView._aim_plough`; hitch to hitch under 3 cm on the shipped fields, the hand slides on the stilt by at most 0.25 m).
Known limitation, accepted for a follow-up card: in the turn clips (exit, turn, enter; about 3.6 s of every ~27 s furrow cycle) the plough is not hitched. The clips swing it 77 degrees aside and tip it 58 degrees, with the beam tip under the ground, while the team stays 2.6 m ahead of the ploughman, so hitch to hitch is 2.4 to 3.3 m (median 2.7 m). Aiming the ard at the team there needs the hand to slide about 0.6 m and makes the ard jump (1 m in one frame at the team's swing), so it is left as the clips pose it. The fix belongs to the clips (tip the ard onto its side with the beam end at yoke height) and/or a team that walks the U-turn.
Adding a craft or a homestead means adding JSON, not code. Animals are data too: a cycle of clips whose length divides the day. Models are referred to by asset ID, never by path.

## Run

```sh
godot --path .      # click a person for the card; M mute, Space pause, Q/W/E speed, 0/Esc overview, 1-9 homestead, Tab next,
                    # F follow, L cutaway, C language (cs/en), right-drag orbit, wheel zoom; slider scrubs the day
checks/museum_village/run.sh                     # core, data, terrain, boundary, view and plough-team checks (headless)
```

## The village

The village layout and the ground are **F/R**: no house plan or terrain model of Březnice survives. `tools/organic_layout.py`
chose the house positions on a fictional height field (seed 11); `tools/build_village.py` levels a platform under each house and
work yard, routes the paths over the terrain and writes `data/villages/breznice*.json`.
Two house types alternate (`house_types` in `data/villages/breznice-layout.json`: odd houses type A, HOUSE-004, 15 × 5.5 m, three rooms;
even houses type B, HOUSE-005, about 8.5 × 5 m, one room), in plain, limewashed or patterned daub; both are R/F reconstructions after
other Bohemian sites, not plans of Březnice houses.
The house models are revision r002 (SB-033): round-wood posts, irregular spacing and uneven daub and thatch show traces of hand work (evidence class F/R: the shapes are our reconstruction choices after other sites, not plans of Březnice houses).
The type A model has 6 758 triangles and the check allows it 7000 (type B: 5000); details in `assets/HOUSE-004/r002/PROVENANCE.md`.
The fields carry furrows (SB-008): `data/villages/breznice-furrows.json` (written by `tools/build_furrows.py`) gives each field a direction and a
depth, width and spacing inside the ranges measured with a replica of Walle-type ards from Opava (Kováčik et al. 2022: 8–12 cm, 4–6 cm, 18–35 cm; evidence R, a regional
analogy; no ard or furrow is attested at Březnice). `view/furrows.gdshader` draws them from world position on one flat patch per field: no instances,
no texture file and no instances. Since SB-037 they are not ruler-straight, following the research note E-furrow-irregularity.md (studio research, 2026-11-21; it lives in the private studio repo, `content/research/museum-lba/`, and is deliberately not copied into `research/` here: data cite it by name only, not as a `research/` path, and the build is its own record, `core/furrow_field.gd`).
`core/furrow_field.gd` builds, at start-up and from the field's record alone, a table of every furrow (lateral position, depth, width, U or V profile, where it exists)
and the shader reads it. What is in it, and what the evidence is:
- Class F (our choice, no source gives an amplitude): a gentle arc shared by all furrows of a field (1.0–2.5 % of the furrow length, sign per field) and a turn-in over the last 2–5 m toward the side where ploughing progresses
  (Nielsen 1986, Iron Age Denmark, describes slightly curved furrows and turns near the end; the existence of the effect is E there and an analogy here, the sizes are ours);
  per-furrow wander with sd about 4.5 cm, wavelength about 12 m, correlated with the neighbour (rho 0.7–0.85) but stationary, so it does not grow across the field; slope limit 0.05;
  start and end offsets (sd 0.5 m, at most 1 m), lifted gaps (about 0.3 per 10 m, 0.2–0.8 m long), clods (2–8 % of the area).
- Hard limits kept by the generator and tested (checks/museum_village/test_data.gd): the lateral gap to the previous furrow is clamped to 18.7–35 cm, so the perpendicular distance is at least 18 cm
  (the experiment's 18–35 cm, Kováčik et al. 2022, class X for the range, R for applying it here); every furrow's heading stays under tan 0.28; normal depth 8–12 cm and width 4–6 cm
  (the experiment's means); deep patches (12–18 cm deep, up to 8 cm wide, which the experiment also reports) are rare, short and at most 2 % of a furrow's length.
- Not documented in any source read: the sd, wavelength, correlation, patch and gap rates; no ard or furrow is attested at Březnice, and the source furrows come from human-drawn replica ards, not oxen.
`tools/build_furrows.py` draws each field's parameters (inside the ranges of the note) from a per-field seed into `data/villages/breznice-furrows.json`; the model is code, the table is deterministic.
The profile is band-limited (blurred by the pixel footprint) and fades out when the period itself nears 2.5 screen pixels; beyond that the shader does no work. Measured in a software-rendered web build (1280x720, FOV 40): the furrows read to about 39 m at the default pitch (11.9-17.1 m before SB-037) and to about 13 m at a low pitch.
The patch carries the ground's own colour, so a field looks the same as before wherever the pattern has faded.
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
- `view/sound_view.gd`: sets the volumes of the buses `Ambient`, `Sources` (3D sources), `Craft`, `UI` under `Master` (they are defined in `../default_bus_layout.tres`, see "Sound on the web: buses and the output check"; offsets in `data/sound.json`), keeps volume and
  mute, eases gains (starts silent and fades in; default volume 0.5 = -12 dB), ducks the scene buses while paused and silences everything, immediately (no fade), when the window/tab loses focus (it fades back in on return), and emits `one_shot` for events of the elapsed frame (not when scrubbing, running backwards or faster than x10).
  `levels` holds the current layer loudness for SB-019 to mix. The choice is stored in `user://sound.cfg` (`ConfigFile`; a failed load or save is
  ignored and the session just keeps the choice). Controls: "Sound" button and a volume slider in the bottom bar, key `M`. On a phone (narrow layout) the bar shows only a mute button, a speaker icon of
  the same width muted or not (44 x 44 px touch target, the bar is 46 px high), and no volume slider; volume there is the device's own (owner decision, SB-034).
  A phone bar keeps the day slider at 48 px or more and stays inside the screen at 320, 360 and 400 px, in Czech and English, running and paused (`test_ui.gd`, which measures the right edge of the
  rightmost visible control; its mutations without the slider floor, without the tighter gaps, without the short "Řez" label, with a 26 px icon or a 38 px bar all fail). At 320 px "Řez domem" is shown as "Řez" (full name as tooltip).
  Supported minimum width: 320 px (English fits down to about 305 px, Czech to about 295 px); below that the bar overflows rather than squeezing the day slider under 48 px.
- The only audio asset is a 0.25 s test tone generated by script (`SoundView.make_tone`, 11 kB in memory, not in the pck), played on the `UI` bus when the slider is released.

### Ambient (SB-019): loops rendered by script

Atmosphere (F): the sound of the landscape is a synthetic stand-in for how a place like this might have sounded (birds at dawn, wind and insects by day, a quiet dusk, crickets at night), not a reconstruction of Bronze Age sound; no voices, no modern sounds.
All five layers are provisional until recordings replace them (SB-022). Nobody has listened to them yet: the checks below are numbers, not hearing.

- Layers (`ambient.layers` in `data/sound.json`): `dawn` (bird chorus), `day` (leaf rustle, insects), `dusk` (soft evening), `night` (crickets, distant low noise), `wind` (always, louder in a storm). Their loudness over time is the pure `Soundscape.layers(t, season, weather, day_length)`, unchanged; `SoundView` eases every layer's gain towards it (time constant `fade_tau_s`, 0.4 s) so scrubbing the time slider crossfades instead of jumping, and multiplies it by `Soundscape.proximity(camera distance)`: the ambient falls to 30% when the camera is within 12 m of what it looks at and is full beyond 90 m (SB-020 sources will take over close up).
- Rendering (`core/ambient_synth.gd`): mono, 22.05 kHz, 6 s per loop (`length_s`), from a recipe and the seed `ambient.seed`; no engine random generator (integer noise), so the same data gives the same samples. It runs in slices of about 3 ms per frame (`budget_us`) after start, wind first; a layer is ready when both its copies (below) are rendered. Filtered noise is cross-faded end into start; cricket and insect voices use whole cycles per loop and bird chirps wrap around, so the end runs into the start with no step in value or slope. Generated sound adds nothing to the pck.
- Soft by design (SB-040, after the first listening found sharp pitches; still numbers, not hearing): no carrier above 3 kHz (cricket pulses 2.2-3.0 kHz, 3.06 kHz at the top of a vibrato, with a vibrato `vib` [Hz rate, Hz deviation] so no tone is a pure line), raised-cosine pulse edges, bird chirps 70-160 ms, without a harmonic (`birds.h`), none starting or ending above `birds.f_max` = 3.5 kHz (the start pitch of a phrase is drawn from 1.5-3.0 kHz and lowered when its 8 % drift per syllable and its sweep would pass the cap; so chirps run from about 0.7 to 3.5 kHz, a measured 0.74-3.49 kHz over both copy seeds, and `test_ambient.gd` asserts the cap on the real chirp plan of both), beds low-passed lower, voice gains and loudness (`rms`) lower. Energy above 4 kHz (Welch, 6 s loops, seed 1150 / second copy seed 9069): day 0.54 -> 0.10 / 0.54 -> 0.10, dusk 0.16 -> 0.02 / 0.19 -> 0.02, night 0.96 -> 0.00 / 0.96 -> 0.00, dawn 0.43 -> 0.001 / 0.45 -> 0.001; `test_ambient.gd` keeps it below 0.05 (day 0.12) for both seeds of every layer. The `bird` and `dog` one-shots in `data/sound.json` only emit events (no sound plays from them yet).
- Two copies per layer (`overlap`), from two seeds: each loop has a sin fade baked in (`_run_apply`) and a second player starts half a loop later, so the two windows add to constant power. Reason, from the engine source: on the web a looping sample is restarted from the `ended` event and always from the offset it was started at, not sample-accurately (see below); the fade hides the short gap under the other copy. Desktop loops are gapless either way. The second copy is rendered from another seed (`AmbientBank.COPY_SEED_STEP`; the seed also moves the phase of phrases, pulses, carriers and gusts): two copies of one rendering half a loop apart would add to a signal that repeats after half a loop (measured: 4 s instead of 8 s).
- Period (measured, `test_ambient.gd`): the correlation of the 50 ms loudness envelope of the playing pair with itself, over 20 s: at half a loop (3 s) wind 0.03, day 0.27, dusk 0.00, night 0.39, dawn 0.07 (the guard is below 0.6); at a whole loop (6 s) 0.99 to 1.00. With both copies from one seed it is 0.99 to 1.00 at half a loop. So each layer repeats after its 6 s loop, not sooner; that is still a short loop (the same bird phrase returns every 6 s): a listening and design question for the owner, and a reason to replace the layers with longer recordings (SB-022). Where the day's tonal voices (crickets) have a fixed rhythm, that rhythm is audible by nature.
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

  The formula behind it: a layer that has been heard costs 2 stored buffers (one per copy); one that is playing costs 2 more, plus a transient one at each restart; so two sounding layers after a whole day are 10 stored + 4 playing. Before it was 5 stored + 10 playing. Not changed by this: stereo float at 48 kHz in the browser, whatever the source (16 kHz would not help the browser buffers). Native desktop: rendering the ten loops (five layers, two copies) takes about 1.3 to 1.9 s of work, spread over about 450 frames at 3 ms per frame; in the web build 2.2 s of work in about 15 s of wall time (the wind, then the layer of the current time of day, first), against 2.6 s in 18 s for the build before (same machine, run one after the other); no console error, 6 starts of players at the beginning and about 0.9 loop restarts per second afterwards. `sound.apply` costs a few tens of microseconds per frame natively; sample mixing runs in the browser. Restart gaps were measured on the build before, from `AudioContext.currentTime`: 0 to 32 ms (0 to 53 ms in the independent review), hidden by the baked fade; this build keeps the design and was not measured again. Not measured: phone, Firefox, Safari, battery, and anything heard (the hidden tab: see below, SB-034).

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
- Hidden tab (SB-034): headless Chromium cannot really hide a page through DevTools (`visibilityState` stays `visible` after `bringToFront`, a second tab, a minimised window), so this was
  checked by driving the real build with the events a tab switch causes and measuring the real audio graph (`checks/web_audio/check_hidden.mjs`): a `visibilitychange` to hidden, canvas/window blur, and
  DevTools `Page.setWebLifecycleState` frozen. Finding: on the build before this change a `visibilitychange` alone did NOT silence the ambient (peak 0.030 while "hidden"); only blur did (peak 0.00001).
  Fix: `SoundView` listens for `visibilitychange` itself on the web (`JavaScriptBridge`; the callback runs inside the event, so Master goes to silence with no frame needed) next to the focus path.
  After the fix, hidden by visibility, blur or both: peak at the destination about 0.00001 (positive control: ambient about 0.028 while visible); shown again: the ambient is back and the same number of loops
  play; a user mute survives hide and show. A frozen page that was not hidden keeps playing (0.038: the audio thread runs on without the page), so the mute has to happen before a freeze; hidden then frozen is silent (0.00002).
  Not checked: a real tab switch in a headed browser, Firefox (not available), Safari/iOS, phones, anything heard. One-shot events play no sound yet.
  Any window focus loss on the desktop (not only a hidden tab) also silences the museum.
- For the next cards: recordings must be Ogg Vorbis/WAV `AudioStream`s played as samples; do not rely on bus effects (low-pass for distance, reverb) or on `AudioStreamGenerator` on the web. Test positional sources in the web build.

### Sound on the web: buses and the output check

**Correction (SB-039).** From SB-018 until this fix no sound reached the speakers on the web build. The buses were created at run time with `AudioServer.add_bus()`; in Godot 4.5.1 Web
that puts every new bus before `Master` in the browser's bus list and then connects `Master` to another bus, so `Master` was cut off from the destination and the buses
formed a loop (the `AudioWorklet` was the only node left feeding the destination). The statements in this README and in the SB-018/SB-019 records that were based on browser measurements
(the `AudioContext` state after load or a click, restart gaps, buffer counts, memory) describe a graph that nobody could hear; they are observations of the engine's activity, not evidence that sound arrived.
Nothing in them was a recording of the output, and nobody listened. What the later checks establish is below.

Cause, in the Godot 4.5.1 sources (<https://github.com/godotengine/godot/blob/4.5.1-stable/>):
`servers/audio_server.cpp` `AudioServer::add_bus` (l. 859, call at l. 910) calls `add_sample_bus(p_at_pos)` with -1 for "append"; `platform/web/js/libs/library_godot_audio.js` `Bus.addAt` (l. 887-892) creates the bus,
then `Bus.move(id, index)` (l. 871-879) removes it and does `buses.splice(toIndex - 1, 0, movedBus)`, i.e. `splice(-2, 0, ...)`, which puts the bus before `Master` in every case, but only the first two added buses go to the very front of the list; later ones go to `length - 2` of the filtered list, i.e. before the last two entries (with SB-018's four buses the browser order becomes `[Sources, Craft, UI, Ambient, Master]`, measured by the reviewer);
`Bus.create` (l. 898-908) sends every bus to `getBus(0)`
and `set_sample_bus_send` (l. 1482-1494) resolves the target by index, so `Master` ends up sent to a child bus. Buses built by `AudioServer.set_bus_layout` (`servers/audio_server.cpp` l. 1735-1795 calls
`set_sample_bus_count`, which creates them in order) keep their order. `main/main.cpp` l. 3721 calls `AudioServer::load_default_bus_layout` (`servers/audio_server.cpp` l. 1623-1632), which loads the project setting `audio/buses/default_bus_layout`.

Fix: the buses live in `default_bus_layout.tres` (Master, Ambient, Sources, Craft, UI; sends to Master; offsets as in `data/sound.json`, compared by `test_sound.gd`) and `project.godot` names it.
Do not add buses at run time (`add_bus`, `move_bus`). `SoundView._init` still adds a bus that is missing from the layout, which is fine on desktop. On the web, one missing bus is harmless (Master stays at index 0 and buses are addressed by index; the reviewer measured all four buses correct with `UI` removed from the layout), but if the whole layout is missing and every bus is created that way, the web build is silent again; the output check below catches that case. The `[audio]` line in `project.godot` is redundant (it is Godot's default path) and is kept for being explicit; the real guard is the file, and `test_sound.gd` asserts the bus names and sends that the engine loaded at startup.

Check of the real output: `checks/web_audio/check_output.mjs <web export dir>` loads the export in Chromium, redirects everything connected to the page's `AudioContext.destination` through an AudioWorklet that records the peak, and
asserts (1) positive control: an oscillator at gain 0.01 sent through the same point is captured as 0.0100; (2) the 0.25 s UI test tone at volume 1.0 arrives with the peak the bus settings predict (0.366 x UI -6 dB = 0.1836, +-30 %);
(3) at volume 0.5 it is 12 dB lower (+-1.5 dB); (4) at volume 0 nothing arrives (< 0.0005); (5) every buffer source reaches the destination when it starts. Since the ambient (SB-019) plays from the start of a visit, the check first requires that the ambient reaches the destination (`ambient`: peak >= 0.005, measured about 0.025 to 0.030), then presses Space (the pause mutes Ambient, Sources and Craft, not UI) and requires a window without ambient (`quiet`, peak < 0.0005) before the tone windows, so the ambient cannot add to the tone peaks; the `silent` window also requires that the tone really started in it. Measured on this change: before the fix peak 0.0000 and 0 of 3 sources reached the destination; after, 0.1835 / 0.0459 (12.0 dB) / 0.00002 and 3 of 3.
Run it: `godot --headless --export-release "Web" build/web/index.html`, then in a scratch directory `npm install --no-save playwright-core` and
`CHROMIUM_PATH=/usr/bin/chromium node /path/to/checks/web_audio/check_output.mjs /path/to/build/web` (exit 0 = all PASS; needs Node >= 18 and a Chromium; no sound card: the context runs against Chromium's silent sink;
`HEADED=1` shows the window). It takes about a minute (software WebGL). The volume tones are measured at a settled gain: the slider is set, the check waits 2 s for the Master fade (3 per second) and clicks the same position again, so the tone plays with no fade running.
`checks/web_audio/check_hidden.mjs <web export dir>` (same setup, about 3 minutes) is the hidden-tab check described above: positive control (visible ambient peak >= 0.005), silence while hidden (< 0.0005) by visibility, blur and both, resume without a stuck mute or doubled loops, the user's mute surviving, and the frozen runs; both scripts share `harness.mjs`. It is also run by the `web-audio` job, report-only.
In CI the job `web-audio` is report-only: `deploy` does not need it. It goes back into `deploy.needs` after 10 consecutive green runs in CI on pull requests and main (no retry used); the job retries once and prints both attempts. It measures what is sent to the destination, not what a sound card or a speaker produces, and it was run in Chromium only.

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
