# SB-056b runtime evidence (not for main)

Branch with pictures only, for the review of the SB-056b pull request; delete it after the review.

- `0`-`4`: Godot 4.5.1, GL Compatibility, GPU (Mesa Intel UHD 620), the real main scene rendered into a fixed 1280 x 800
  SubViewport by `capture.gd` (village paused at 09:36, Czech): card with the button, Celek, Otvor, Celek again, Otvor at
  midnight (village dark, stage unchanged). `5`-`6`: the same run at 390 x 844 (phone layout, English). State, camera
  transform and light energies of every picture: `capture_log.json`.
  Pixel comparison of the stage area: 1 vs 3 identical, 2 vs 4 identical (the village sun does not reach the stage).
- `web_*`: the local Web export (4.5.1 templates) in headless Chromium (SwiftShader), driven by `web_viewer.mjs`:
  key 5 (hs-05), the card button, Hole, Whole, Back.
