# SB-017 runtime evidence (not for main)

Pictures and logs for the review of the SB-017 pull request (light); delete the branch after the review.

- `pred_*.png` / `po_*.png` (before = main b2f450b / after = this branch): Godot 4.5.1, GL Compatibility, GPU (Mesa Intel UHD 620),
  the real main scene rendered into a fixed 1280 x 800 SubViewport by `capture.gd` (window on workspace 9, vsync off), village
  paused, Czech, **weather off** (so the light of the day is seen alone; `po_prehled_dest_po` has it on: rain at t=1226).
  Times of day (fraction of the day; 0.25 sunrise, 0.75 sunset): `usvit` 0.265 (06:21), `rano` 0.30, `poledne` 0.50,
  `odpoledne` 0.68, `zapad` 0.745 (17:52), `soumrak` 0.78, `noc` 0.92 (22:04).
  `prehled_*`: overview. `ohen_zblizka_den` / `_pozdni_odpoledne`: the cook (hs-07) at her fire at 0.45 and 0.70 (late, low sun).
  `dum_zblizka_vecer` / `_noc`: her house at 0.80 / 0.92 (she is at home: nobody works after dark in the schedule);
  `*_od_dveri`: the same from the door side (after only); `dum_zblizka_noc_rez`: cut away, the sleeper by the hearth;
  `*_nizsi`: lower quality (4 lights, no fire shadow). `telefon_*`: 390 x 844, phone layout.
  Per picture: sun energy, colour and pitch, sky, ambient, mean luma, the luma of the middle of the screen (`subject_luma`),
  live and shadowed lights: `capture_log_shots_*.json`.
- `perf/*.json`: frame times (`capture.gd perf`), same laptop, 900 warm-up frames, then 3 repetitions x 300 frames per state and
  quality, order rotated; runs in the order main (`main_pred`), branch, branch (`branch2`), main (`main2`). Means: see
  museum/README.md "Light budget". Single runs differ by up to 40 %.
- `web/`: local Web export (4.5.1 templates) in headless Chromium (SwiftShader), `web_light.mjs`: desktop start, x40 through a
  day and a night (rain on that night), paused; phone 390 x 844 start; phone with `prefers-reduced-motion: reduce`.
  Console: only the local server's missing favicon (404). SwiftShader runs at about 1 frame per second: not a device measure.
