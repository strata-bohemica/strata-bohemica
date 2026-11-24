# Museum (Godot 4.5.1, GL Compatibility)

A digital open-air museum of Bohemian prehistory. M6: the plougher walks a real path to a field and ploughs up and down it with two oxen; eleven more homesteads work in their yards. M4: click a person to read how well their craft is supported (evidence, reconstruction, what is unknown, sources), in Czech or English. Behind it, a village on uneven ground with eleven yard homesteads (grinding, cooking, weaving, woodworking, spinning, parching, threshing, hide scraping, milking, daub treading, and hand-forming a clay bowl as an experimental variant without firing, SB-058), animals, trees and hearth smoke, working from dawn to night.
Everything the scene does is a pure function of time; the view only applies it.

```
core/    day clock, soundscape, weather, lighting, craft timeline, craft props, animals, travel, schedule, terrain, card, i18n, picking, schema,
         object view   (no nodes, testable headless)
data/    period, crafts, homesteads, village + terrain, asset catalogue      (JSON, shared with the web page)
assets/  catalogue: "WORK-001/person_grinding" -> path, clips, anchors
view/    thin Godot adapters: sound, pose driver, homestead view, terrain view, village view, object stage, weather, light
ui/      card panel, time bar, object viewer and weather switch (they draw what core/card.gd, core/object_view.gd and the app give them)
app/     the main scene and the loader that assembles the village
```

A person who moves while working (the plough) is a pure function of the time they have worked: `core/travel.gd` walks a line,
turns round and walks back; the schedule keeps their place through the meal and walks them home from wherever they stopped,
after a commute along the least-cost path from the yard to the field (`tools/build_village.py` writes it as `sites`).
The plough team (yoke and oxen) is tied to the ploughman, not to the plough: the turn clips swing the plough aside and tip it about 58 degrees, so the team keeps its place in his frame and stands on the ground under each ox, leaning to the slope (at most 20 degrees; `HomesteadView._team_pose`, checked in `test_plough_team.gd`).
The team has its own frame in the schedule state (`team`: position, heading, walking): the ploughman's while he works or eats; the line start before the day's work; and after it the team turns, walks back to the line start and turns to face along the line (`Schedule._team_going_home`, 3 s per half turn, 0.6 m/s; our choice, class F). So it rests at the line start through the night and starts the next day's work where it stands. Before SB-042 it was posed from the worker skin, which stops updating after work: the oxen stood where the ploughman had stopped all night and jumped 5.93 m at the start of work every day from day 2 (19.95 m on the first day).
The plough stays hitched to the team through the whole furrow cycle, the turn included (`HomesteadView._aim_plough`, `_team_shift_to_hitch`; SB-036, SB-041). The ard's grip stays on the ploughman's hand in every clip (0.00001 m); the ard only turns about the grip. It is held level (the ploughman's heading, no roll) and turned about the grip until its yoke hitch points at the team's beam hitch. The grip-to-hitch distance is fixed by the ard, so the team gives way instead: the whole team is shifted horizontally along the line from the hand, by up to a few dm in the turn clips, until the two hitches are one ard apart. Hitch to hitch is under 3 cm everywhere, except in the first and last 0.35 s of each work segment, where the shift is eased in and out so the oxen do not jump when the plough appears or goes (up to 0.43 m for about 0.15 s). Earlier text here said the hand "slides on the stilt". That was wrong: the old aiming slid the whole ard along its beam axis, away from the hand, by up to 0.16 m walking and 0.25 m in the enter and exit clips, and the beam axis is not the stilt.
In the turn (exit, turn and enter clips; about 3.6 s of every ~27 s furrow cycle) the plough lies on its side: rolled 90 degrees about the line from the grip to the yoke hitch (smoothly over the exit clip, back over the enter clip), so the share is at least 0.5 m above the ground. The clips themselves swing the ard 77 degrees aside and tip it 58 degrees nose down, with the share about 1 m under the ground; the ard's orientation from the clips is not used, only where the hand is. The share is in the soil (down to 12 cm) while the team walks, as intended. Known limits: the ploughman's arms are those of the clip, which holds the ard aside, so his hand is not turned to match the handle's roll in the turn (not checked on a display, only numerically). On the shipped field the aiming turns the ard at most 13.5 degrees from level (limit 45) and the team gives way by at most 0.52 m (limit 0.6 m); the tests fail if the limits start to bind.
Adding a craft or a homestead means adding JSON, not code. Animals are data too: a cycle of clips whose length divides the day. Models are referred to by asset ID, never by path.

## Run

```sh
godot --path .      # click a person for the card; M mute, Space pause, Q/W/E speed, 0/Esc overview, 1-9 homestead, Tab next,
                    # F follow, L cutaway, C language (cs/en), P weather, right-drag orbit, wheel zoom; slider scrubs the day
checks/museum_village/run.sh                     # core, data, terrain, boundary, view and plough-team checks (headless)
```

The keyboard drives these shortcuts only: no button or slider takes the keyboard focus (`focus_mode = FOCUS_NONE` in `ui/`),
so after a click on a button a key still does exactly one thing (SB-059 R2-1: Space used to press the clicked button again
as well as pause, and Tab moved the focus instead of choosing the next homestead).

## The village

The village layout and the ground are **F/R**: no house plan or terrain model of Březnice survives. `tools/organic_layout.py`
chose the house positions on a fictional height field (seed 11); `tools/build_village.py` levels a platform under each house and
work yard, routes the paths over the terrain and writes `data/villages/breznice*.json`.
The long axis of the houses runs roughly north–south. That is our inference (F) from the north–south long pits of Březnice (Chvojka et al. 2019, 269–270),
not an attested house orientation; house 57, the source of type A, is NW–SE. The village is also denser than Březnice: 12 houses in four clusters
(number and size of the clusters are F) on about 1.5 ha, against a site of about 13 ha with about 70 houses over time, whose land could have supported at most about 20 houses at once (Šálková et al. 2022: "could have sustained up to 20 houses at the same time", a carrying capacity, not a counted number).
Two house types alternate (`house_types` in `data/villages/breznice-layout.json`: odd houses type A, HOUSE-004, 15 × 5.5 m, three rooms;
even houses type B, HOUSE-005, about 8.5 × 5 m, one room), in plain, limewashed or patterned daub; both are R/F reconstructions after
other Bohemian sites, not plans of Březnice houses.
Type A follows house 57 at Březno u Loun, whose dating is uncertain (the excavator also considers the Migration Period; Sklenářová 2012, 114),
and the model adds a central row of ridge posts that house 57 does not have (Pleinerová and Hrala 1988, PDF p. 56). Type B follows the one dwelling
of the Liptice farmstead, whose reading as a house is uncertain, and the museum shows none of the farmstead's other buildings (Jiráň 2008, 169–171; Sklenářová 2012, 114).
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

## Object viewer (SB-056)

A craft card can offer a close look at one object: `card.detail` in the craft's JSON names the model (asset ID), the views
(the first is the whole object; each aims the camera at a model anchor and sets its own light) and notes of four kinds:
`find` (what was observed), `model` (our own choices in the model), `hypothesis` (an interpretation) and `related` (another
exhibit). Another object is JSON, not code. Today only the weaving card (hs-05) has one: the loom weight LOOMWEIGHT-001 r002,
"Celek / Otvor / Zpět" (Whole / Hole / Back), the hole in raking light at 16.9 degrees to the face, as in the modelling previews.

```
card button -> app.open_detail -> core/object_view.open (always the whole) -> view/object_stage.apply(framing) + ui/object_viewer.show_page
Celek/Otvor -> app.detail_go -> object_view.go -> the same      Zpět/Esc -> app.close_detail -> the card again
```

The stage is a `SubViewport` with its own world (`own_world_3d`): its own camera, light and environment, so the sun of the
village never reaches the object and the viewer never touches the village or its clock (the village stays a function of time;
the object looks the same at noon and at midnight). It renders only while the viewer is open; the model is loaded on first use.
On a phone the viewer fills the screen above the time bar, picture on top, text below; every button is at least 44 x 44 px.
Checked in `checks/museum_village/test_object_view.gd` (data and wording, cs/en parity, the tour whole -> hole -> whole with
three mutants of the core that must fail, the stage light at night, phone widths 320-400 px with real taps).

## Weather (SB-015)

The weather is a **simulation (F)**: plausible Central European weather of our choosing, not a reconstruction of the weather of Březnice in 1150–1000 BCE, which no source gives. The switch in the top right corner (on a phone under the speed button) says so on two lines, with its key: "Počasí [P] / simulace" / "Weather [P] / simulation", and the note (simulation, F) as tooltip. It used to read "Weather (F)", which looked like the F key, and F is Follow (SB-059 R2-3).

```
core/weather.gd   weather(t, season) -> {cloud, rain, fog, snow, wind} 0..1; shading(w) -> light factors; storm, smoke_push, sway
view/weather_view.gd   app._refresh: base light of the day -> weather.apply(t, base, camera) -> sun, sky, ambient, fog, rain, smoke, trees
ui/weather_toggle.gd   on/off and quality (lower/higher), key P
```

- Pure function of time, like the rest of the scene: each channel is smooth value noise (hashed values at knots 120 s and 40 s apart, eased between them), no state and no random generator, so the time slider, scrubbing backwards and the speeds x1/x10/x40 show the same weather for the same time. The knots repeat after 7 days (2520 s), so the weather has its own period, a whole number of days. The day's own cycles (fire flicker, smoke on/off, animals, work) do not read the weather and still repeat every day; the whole scene repeats every 7 days.
- Over the 7 days (measured in `test_weather.gd`): above half strength rain 15 % of the time, cloud 50 %, wind 24 %, mist 4 % (it forms around dawn and the wind blows it away); clear 27 %. A visit starts (07:12 on the first day) in clear weather. Neighbouring times 0.1 s apart differ by at most 0.01 per channel.
- Snow is only a state of the function: precipitation falls as snow when `season` (0 winter .. 1 summer, as in `core/soundscape.gd`) is below 0.3. Until SB-016 brings seasons there is one climate (season 1), so there is never snow; snow has no picture yet (SB-016).
- The weather multiplies the light of the day, it does not replace it (`core/lighting.gd` computes that base light, SB-017): sun energy x0.28 under full cloud (less in rain and mist), the sky turns towards overcast grey and darker, the ambient a little stronger. Mist is `Environment.fog` (exponential depth fog, supported by GL Compatibility) in the colour of the sky; rain and cloud add a light haze.
- Rain is one mesh of thin streaks in a 48 x 28 x 48 m box around the camera (`view/rain.gdshader`): 4000 streaks at the higher quality, 1200 at the lower, one draw call, moved in the vertex shader by the museum clock (not the engine's `TIME`), so paused rain stands still and scrubbing shows the rain of that time. The streaks fall at 7 m/s and drift 1.5 m/s with the wind, the way they lean (`WeatherView.rain_drift`; the shader draws a streak at its place + drift, modulo the box). No particle simulation runs on the CPU (the web build is single-threaded). It does not wet the ground (a wet surface was left out: the house and ground materials would have to change).
- Wind (fixed direction, F) pushes the hearth smoke sideways (the smoke's `gravity`) and leans the trees about their bases by 0.1–2.3 degrees at full wind, a slow sway (node rotation only; the village data are not changed). The ambient wind and the bird layers of the soundscape follow `Weather.storm` (the larger of wind and rain).
- Settings: weather on/off and quality, saved in `user://weather.cfg`. Before the visitor chooses, weather is off when the browser asks for reduced motion (`prefers-reduced-motion: reduce`, read on the web through `JavaScriptBridge`), and the quality is lower on a phone or tablet (`web_android`, `web_ios`). The lower quality draws fewer raindrops and keeps the trees still; fog stays.
- People do not react to the weather (they work outdoors in the rain): changing what they do would change claims about the crafts, a separate card.
- Checked in `checks/museum_village/test_weather.gd`: purity (same t, any order, negative times), range, continuity, the 7-day period and days that differ, snow only in the cold, the light multiplied not replaced, the view the same for a time whatever was shown before, fire and animals repeating a day later under other weather (with a positive control), the switch, key P, the quality, the saved choice, scrubbing and x1/x10/x40 in the app, the phone layout (inside the screen, 44 px, off the time bar), the labels, the rain falling and drifting with the wind between t and t + 0.2 s (before and after t = 0); in `test_ui.gd` the phone's top line, speed button and weather buttons apart at 320/360/390/400 px in cs/en with a long name, and taps on the weather buttons and the gap between them staying with them; mutants that must fail: a counter between calls, a random generator, steps between knots, knots that never repeat, snow regardless of season, a one-day period, a view that remembers the last weather, and rain moving up or against the wind.
- Frame time, measured only on one Intel UHD 620 laptop (Mesa, native Godot 4.5.1, GL Compatibility, 1280 x 800, vsync off, overview). The author's runs (mean of three interleaved 300-frame runs): clear 16.0 ms with weather on or off, rain +1.3 to +1.5 ms against weather off (19.9 ms high / 20.1 ms low against 18.6 ms), mist +2 ms (the fog). The independent review on the same laptop: clear about 0 ms, rain +1.5 ms, mist +3.4 to +4 ms. The same build differed by up to 40 % between runs, so these are rough. Not measured on a phone or on a reference device: SB-009 lists none yet, so the cost on the reference GPU is unverified.

## Light (SB-017)

The light is **artistic (F)**: the colours of the sky and the sun and the flicker of the fires are chosen to read well on screen (a dark night lit by warm fires, a cool dawn, a white noon, a warm sunset with long shadows). It is not a reconstruction of how Březnice looked by night or day in 1150–1000 BCE; no source gives that. The sun's path is the old one (highest 65 degrees at noon) until SB-016 brings seasons.

```
core/lighting.gd   base(t) -> sun energy, colour, pitch, yaw; sky; ambient colour and energy; hearth(t); fire(t, phase, motion); budget(lights, camera, ...)
view/homestead_view.gd   each fire's and hearth's energy, colour and place from core/lighting.gd
view/light_view.gd   which positional lights are on and which cast a shadow (Lighting.budget), from where the camera is
app/museum_village.gd   base light -> weather.apply (the weather multiplies it) -> sun, sky, ambient; then the light budget
```

- Pure function of time, like the rest of the scene: no state, no random generator. The light budget depends on the time and the camera only, never on what was shown before. Every fire cycle is a whole number of cycles per day (360 s), so the fires repeat every day; `test_lighting.gd` checks this for t, t + 1 day and t + 10 days, and across midnight.
- Sun: white at noon, a pale rose sun and a cool blue sky at dawn, an orange sun and a rose-amber sky at sunset, dark violet then dark blue after it. The sun is low for longer at full strength than before (it reaches full energy at about 9 degrees), so mornings and evenings have long shadows (at 2.6 degrees a shadow is over 4x the height of what casts it). Its turn about the vertical now swings smoothly through midnight (it used to jump back). Below the horizon the sun is switched off, which also saves its shadow map at night.
- Night: no sun, a dark sky and a dim blue ambient (0.25 against 0.6 by day): the fires are what lights the village. Each house has a hearth at its model's `hearth_spot` (type A: the paved hearth of house 57's plan; type B: a central hearth, an F choice of the model) (F: fed while people are at home in the evening and before work, smouldering through the night; its windows follow the period's segments) whose light leaves by the open door: a glowing door opening (an emissive quad, seen from any distance at no light cost) and a warm doorway light on the ground. The nearest hearth (higher quality) is a real light inside the house with a shadow, so the walls hold it and the light comes out through the door as a cone. With the houses cut away the hearth lights the sleeper. The craft fires (cooking, parching) burn only during work and the meal, as before; nobody works after dark in the schedule, so a person working at a fire is seen by day and in the late afternoon only.
- No windows and no smoke holes are lit: the house models have neither (HOUSE-004/005 r002 PROVENANCE: "Smoke through the thatch; no chimney or smoke hole", U); windows wait for evidence (SB-024).
- Fires flicker with slow swells (as before) and fast licks of 3 to 10 Hz at x1, their light moves a few centimetres and turns redder as it dies down. With `prefers-reduced-motion: reduce` the fast flicker and the movement are calmer (x0.3), never off. At x10 and x40 the fast licks and the movement fade out (any cycle faster than 11 Hz on screen fades, gone by 22 Hz; at 60 frames a second it would be random jitter), so only the slow swells stay; x1 is unchanged.
- The weather still only multiplies the light of the day: the app hands `Lighting.base(t)` to `view/weather_view.gd`, which multiplies sun and ambient energy and greys the sky (checked in `test_lighting.gd` with the new light).

### Light budget (GL Compatibility, Godot 4.5.1)

- Read in the Godot 4.5 documentation (lights and shadows): with the Compatibility renderer at most 8 omni and 8 spot lights are drawn per mesh; the project keeps the defaults `rendering/limits/opengl/max_lights_per_object` = 8 and `max_renderable_lights` = 32. Read in the 4.5.1 source (`drivers/gles3/rasterizer_scene_gles3.cpp`): lights without shadow are drawn together in the base pass; each light with a shadow adds one more pass of every object it reaches, and the sun's shadow does the same. An omni shadow in Compatibility is a cube (six shadow passes); dual paraboloid is not supported there (the engine says so at run time).
- The ground is one mesh under the whole village, so more than 8 lights on at once would be dropped arbitrarily on it. The village has 26 positional lights (per homestead a doorway glow and a hearth, plus the two craft fires). So: **live N = 8** at the higher quality and **4** at the lower, nearest to the camera first (lights with no energy take no place); **shadows: 1** at the higher quality (the nearest hearth or fire, at night only), **0** at the lower. A hearth inside a house is on only while it casts its shadow (otherwise its light would pass through the walls) or while the houses are cut away. Every other house keeps its glowing door opening whatever the budget. Switching which lights are live as the camera moves can make a distant pool of light appear or go.
- Quality: the one quality button (top right, "Kvalita"/"Quality") governs rain, trees and lights; lower on a phone or tablet by default; saved in `user://weather.cfg`. The phone layout is unchanged (no new button). The quality button hides while the weather is off, as before; the light keeps the quality last chosen.
- Frame time, measured only on one Intel UHD 620 laptop (Mesa, native Godot 4.5.1, GL Compatibility, 1280 x 800 SubViewport, vsync off, window on another workspace, weather off). Two rounds, each the mean of three interleaved 300-frame runs per state, main and this branch run one after the other (main, branch, branch, main):

  | state | main | higher (8 lights, 1 shadow) | lower (4 lights, 0 shadows) |
  |---|---|---|---|
  | noon, overview | 31.6 / 23.7 ms | 23.2 / 22.0 ms | 21.6 / 24.7 ms |
  | night, overview | 23.3 / 20.5 ms | 23.1 / 18.1 ms | 19.0 / 19.7 ms |
  | night, close to a house | 22.0 / 19.4 ms | 17.4 / 15.9 ms | 16.2 / 14.2 ms |

  Single runs of the same state differed by up to 40 % (heat), so these are rough: no slowdown against main can be seen; at night the switched-off sun's shadow pays for the hearth's shadow. A second fire shadow was not measured. Not measured on a phone or on a reference device (SB-009 lists none), so the minimum frame rate of the web build on a weak device is not established.
- Checked in `checks/museum_village/test_lighting.gd`: purity (same t, any order, negative times), the day's period (and across midnight), continuity of the light of the day and of the hearth, noon white and high, night dark, dusk warmer than dawn and low with long shadows, a lively fire calmer with reduced motion, no frame-to-frame jitter at x10/x40 while x1 is unchanged and the fast flicker fades smoothly with the speed, the app's speed reaching the fires, the hearth's windows against the period's segments, the budget (at most 8 whatever is asked, shadows a subset, a hearth inside only with its shadow or cut away, nearest first, no energy no place), over a day from near and far at most 4/8 lights and 0/1 shadows, no visible light keeping a shadow after higher -> lower quality, night -> day or a cutaway (read from the lights themselves), no shadow by day, night dark away from the fires and lit by a door, the same lights for the same time and camera after scrubbing, the app's light with the weather off and multiplied by cloud with it on, the quality button and its saved choice, no new control on screen; mutants that must fail: a counter between calls, a random generator, a remembered last value, a flicker that does not fit the day, a jump at dawn, a flicker not scaled by the speed, no cap at 8 lights, a light view that keeps the lights it had, a light view that never switches a shadow off.

## Web build

`export_presets.cfg` has a single-threaded Web preset (no special server headers needed). `.github/workflows/pages.yml` exports it in a
`barichello/godot-ci:4.5.1` container and publishes it at `/museum/` next to the diorama page. Locally:

```sh
godot --headless --import
godot --headless --export-release "Web" build/web/index.html     # needs the 4.5.1 export templates
python3 -m http.server -d build/web 8000
```

The first load is about 30 MB of engine and 30 MB of data. The UI scales to the screen density and re-flows on a phone (the card
becomes a sheet along the bottom); touch: tap to select, drag to orbit, two fingers to zoom, drag the card's text to scroll it.
On a phone the x1/x10/x40 buttons give way to one 44 x 44 px button in the top right corner that shows the speed and steps
x1 -> x10 -> x40 -> x1 (the bar has no room for it at 320 px); a tap on it stays with it, it never picks the homestead under it
or moves the camera. The weather buttons sit under it, and the top line wraps before that right-hand column. The card's language and close buttons are 44 x 44 px there too.
Input over the card stays with the card: a finger drag or the wheel scrolls its text and never turns or zooms the camera, and
another homestead's card opens at its top (SB-059; `test_ui.gd` drives real touches and wheel events through the viewport).

## Sound (foundation, SB-018)

This is the frame the ambient, spatial and craft sounds (SB-019..021) plug into. No recordings are shipped yet: the ambient layer is made by script (see Ambient below).

- `core/soundscape.gd`: pure functions of time. `layers(t, season, weather, day_length)` gives the loudness 0..1 of `dawn`, `day`, `dusk`, `night`, `wind`
  (season 0 winter..1 summer is a placeholder, default summer, until SB-016; the app passes `Weather.storm` of the weather on screen as weather 0..1, SB-015). `events(kinds, t0, t1, ...)` plans the
  random one-shots (bird call, dog bark; kinds in `data/sound.json`) from a stateless hash of (kind, time bucket of the day): same window, same events,
  independent of how the window is cut, repeating every day (this needs every `bucket_s` to divide the period's `day_length_s`, 360 s today; `test_sound.gd` checks both, and its `DAY` equals the period's day). No random generator, no state, so scrubbing the slider keeps the scene a function of time.
- `view/sound_view.gd`: sets the volumes of the buses `Ambient`, `Sources` (3D sources), `Craft`, `UI` under `Master` (they are defined in `../default_bus_layout.tres`, see "Sound on the web: buses and the output check"; offsets in `data/sound.json`), keeps volume and
  mute, eases gains (starts silent and fades in; default volume 0.5 = -12 dB), ducks the scene buses while paused and silences everything, immediately (no fade), when the window/tab loses focus or the page is hidden (it fades back in once both are clear), and emits `one_shot` for events of the elapsed frame (not when scrubbing, running backwards or faster than x10).
  `levels` holds the current layer loudness for SB-019 to mix. The choice is stored in `user://sound.cfg` (`ConfigFile`; a failed load or save is
  ignored and the session just keeps the choice). Controls: "Sound" button and a volume slider in the bottom bar, key `M`. On a phone (narrow layout) the bar shows only a mute button, a speaker icon of
  the same width muted or not (44 x 44 px touch target, the bar is 46 px high), and no volume slider; volume there is the device's own (owner decision, SB-034).
  A phone bar keeps the day slider at 48 px or more and stays inside the screen at 320, 360 and 400 px, in Czech and English, running and paused (`test_ui.gd`, which measures the right edge of the
  rightmost visible control; its mutations without the slider floor, without the tighter gaps, without the short "Řez" label, with a 26 px icon or a 38 px bar all fail). "Řez domem" is shown as "Řez" (full name as tooltip) only where the full name does not fit the bar: in Czech at 320 and 360 px, not at 400 or 600 px (`test_ui.gd` checks at 320, 360, 400 and 600 px that the short label is used exactly where the full name would overflow).
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
  environments; neither confirms nor refutes the other. Blurring the canvas/window sets the focus-lost flag (and releases it on focus).
- Hidden tab (SB-034): headless Chromium cannot really hide a page through DevTools (`visibilityState` stays `visible` after `bringToFront`, a second tab, a minimised window), so this was
  checked by driving the real build with the events a tab switch causes and measuring the real audio graph (`checks/web_audio/check_hidden.mjs`): a `visibilitychange` to hidden, canvas/window blur, and
  DevTools `Page.setWebLifecycleState` frozen. Finding: on the build before this change a `visibilitychange` alone did NOT silence the ambient (peak 0.030 while "hidden"); only blur did (peak 0.00001).
  Fix: `SoundView` listens for `visibilitychange` itself on the web (`JavaScriptBridge`; the callback runs inside the event, so Master goes to silence with no frame needed) next to the focus path.
  After the fix, hidden by visibility, blur or both: peak at the destination about 0.00001 (positive control: ambient about 0.028 while visible); shown again: the ambient is back and the same number of loops
  play; a user mute survives hide and show. A frozen page that was not hidden keeps playing (0.038: the audio thread runs on without the page), so the mute has to happen before a freeze; hidden then frozen is silent (0.00002).
  Not checked: a real tab switch in a headed browser, Firefox (not available), Safari/iOS, phones, anything heard. One-shot events play no sound yet.
  Any window focus loss on the desktop (not only a hidden tab) also silences the museum.
  Focus and visibility are two separate flags in `SoundView` (`focus_lost`, `page_hidden`; `in_background` is their OR): any focus loss or a hidden page silences, and the sound comes back only when both are clear, so a page shown again
  while another window has the focus stays silent. The `visibilitychange` listener is removed (and the window focus hooks disconnected) when the view leaves the tree (SB-043; `test_sound.gd` with a stand-in document, because the real
  listener exists only in the web build; mutants: handler ignored, listener never attached, never removed, no cleanup on exit, a flag clearing the other).
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
`checks/web_audio/check_hidden.mjs <web export dir>` (same setup, about 3 minutes) is the hidden-tab check described above: positive control (visible ambient peak >= 0.005), silence while hidden (< 0.0005) by visibility, blur and both, resume without a stuck mute or doubled loops, the user's mute surviving, and the frozen runs; both scripts share `harness.mjs`. It evaluates and reports every window even after a failure (a thrown error becomes a FAIL line of that phase, a window without audio readings fails after 15 s, a watchdog ends a hung run with FAILED), and is also run by the `web-audio` job (`if: !cancelled()`, so also after a failed output check).
In CI the job `web-audio` is report-only: `deploy` does not need it and it is not a required status check (SB-043: both of its steps now turn the job red when they fail; the hidden-tab step no longer has `continue-on-error`). It goes back into `deploy.needs` after 10 consecutive green runs in CI on pull requests and main (no retry used); the job retries once and prints both attempts. It measures what is sent to the destination, not what a sound card or a speaker produces, and it was run in Chromium only.

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

A card may carry `figures` (SB-055): a picture per language (`image: {cs, en}` as `res://` paths), `caption`, `alt` text
and `source` (each `{cs, en}`), and its own E/R/F `class`. They are drawn in an "Illustration" section before the sources;
a click opens the picture over the whole screen, in its own `CanvasLayer` above the app's UI so the click never reaches the
time bar underneath (any click or Esc closes it). A missing picture shows its alt text instead and offers no enlargement.
`Card.figure_problems()` lists what a figure lacks (tested). Pictures live under `research/figures/` (CC BY 4.0, not
under `assets/`, whose PNGs `tools/refresh_assets.sh` deletes) and are imported lossless (`compress/mode=0`): they are
drawings with small text.

Exhibit cards (`museum/data/exhibits/*.json`, built by `Card.build_exhibit()`) describe one find on its own, not a craft.
The first, `store-6-05.json` (storage jar of feature 6/05 with the BREZ-005 section, byte copies of the studio figure,
hashes pinned in `test_data.gd`), is data and tests only: nothing in the village opens it yet. The jar model STORE-001 is
not in `data/asset_manifest.json` and is not shown in the village: showing it sunk in the ground needs a hole in the
terrain, which the terrain has no mechanism for, and a decision on which homestead hosts it. So the SB-055 criterion
"the section is available during the visit" is not met yet.

Every craft carries a card with an evidence class (E evidence at Březnice, R reconstruction, including regional analogy, F fiction: our choice without a source), what is unknown and its sources.
The day rhythm and the layout of the work place are F. No house plan survives at Březnice; the layout is reconstruction.

Licence: code MIT (`../LICENSE`), models, textures and animations CC BY 4.0 (`../LICENSE-ASSETS.md`).
