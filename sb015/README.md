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
