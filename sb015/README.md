# SB-015 runtime evidence (not for main)

Pictures and logs for the review of the SB-015 pull request (weather); delete the branch after the review.

- `*_pred.png` / `*_po.png` (before / after): Godot 4.5.1, GL Compatibility, GPU (Mesa Intel UHD 620), the real main scene
  rendered into a fixed 1280 x 800 SubViewport by `capture.gd`, village paused, Czech. "pred" = weather switched off
  (the scene as on main), "po" = weather on, same time. States: `jasno` t=108 (clear), `oblacno` t=259 (cloud 0.97),
  `dest` t=1226 (rain, cloud and wind ~1), `mlha` t=1903 (mist 0.97), `vitr` t=1561 (wind 0.52, little cloud: wind is
  visible only in motion, smoke drift and tree sway; the stills are nearly the same, the numbers are in test_weather.gd).
  `dest_zblizka_*`: the ploughman close up in rain (higher / lower quality), `vitr_zblizka_po`, `telefon_dest_po` (390 x 844).
  Weather state, sun energy and fog of every picture: `capture_log_shots.json`.
- `perf_*.json`: frame times (`capture.gd perf`), same machine, window on another workspace, vsync off, 900 warm-up frames, then
  3 repetitions x 300 frames per state and setting, order rotated: main before, this branch, main after.
- `web_*`: local Web export (4.5.1 templates) in headless Chromium (SwiftShader), `web_weather.mjs`: start (clear), x40 until
  rain on day 1-3 then paused, key P (off), and a context with `prefers-reduced-motion: reduce` (weather starts off).
  `web_jasno_start`, `web_dest_x40`, `web_dest_vypnuto` and `web_console_default.txt` are from the build before the last fix
  (reduced-motion reading; nothing else changed); `web_reduced_motion_vypnuto` and `web_console_reduce.txt` from the final code.
  Console: only the local server's missing favicon (404).

## Review fixes (`oprava/`)

- `perf_*.json` and `capture.gd`: the key that was called `p95_ms` was the largest of the three runs' mean frame times, not a
  percentile; it is now `max_run_mean_ms`, and `median_run_mean_ms` is the middle of the three sorted run means (it was
  the second run). Values unchanged otherwise.
- `oprava/capture_phone.gd` (Godot 4.5.1, GL Compatibility, Mesa Intel UHD 620, windowed on another workspace, vsync off,
  the real main scene in a SubViewport, weather on, high quality, paused at t=1226, rain):
  `telefon_390_{cs,en}.png` (390 x 844), `telefon_320_{cs,en}.png` (320 x 640), `telefon_320_cs_dlouhe_jmeno.png` (an
  invented long name): homestead selected, top line, speed button (top right) and the weather buttons under it, with
  their rectangles in `capture_phone_log.json`.
- `dest_pohyb_t0.0/0.2/0.4.png`: the ploughman in rain at t, t + 0.2 s, t + 0.4 s (desktop layout). The log gives the
  shader uniforms (`drift`, `anchor`) and six streaks 6-12 m from the camera, placed as the shader places them: each moves
  (+0.24, -1.40, +0.18) m in 0.2 s, i.e. 1.4 m down and 0.3 m along the wind (0.8, 0, 0.6), and 120-170 px down the screen.
