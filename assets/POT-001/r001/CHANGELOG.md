# POT-001 r001 — changelog

## r001 — 2026-11-06 (first return, draft)

### Contents

- **`model.glb`** — one plain lathed ceramic pot:
  - rounded belly, narrower neck, simple outturned lip, open mouth, real rim
  - solid wall (~11 mm) with outward-facing interior surfaces, and a closed flat base (24 mm)
  - 924 triangles, 1 mesh, 1 material (`POT_001_clay`, metallic/roughness, single-sided)
  - one embedded 512×512 procedural base-colour PNG
  - empties `carry_grip` (0, 0.23, 0) and `base_center` (0, 0, 0)
  - origin at the base centre, +Y up, +Z front, unit scale, no animation
- **`source/`** — a reproducible bpy generator with editable profile, wall and irregularity parameters, the saved `.blend`, verification scripts, `build.sh`, `README.md` and check logs.
- **`previews/`** — the six required views (front, side, back, top, isometric, wireframe/statistics) plus these job-specific views:
  - close isometric
  - cavity from above and underside
  - two section views
  - 1.7 m proxy front and isometric
  - game-angle metre grid at orthographic size 25 and 16
- `asset.json`, `PROVENANCE.md`, `CHECKS.md`.

### Departures from the brief

1. Depth (glTF Z) is 0.4509 m, not 0.46 m. This comes from a deliberate, restrained 1 % front/back ovality, which the generator parameter `OVAL` controls (set it to 0 for a perfectly round 0.46 m pot). Width and height are 0.46 m.
2. The rim top dips by up to 4 mm on one side (`RIM_WOBBLE`). The maximum height is still 0.46 m.
3. The Godot check project was created outside the repository at `…/turbo-engine-7b069bd5/POT-001-godot-work/` instead of `/tmp/POT-001-work`, because local agent policy forbids writing to `/tmp`. The commands and script are otherwise as specified.
4. No photo-comparison preview is supplied: the brief allows WM01 only for broad appearance, and no WM01 pixels are reused.

### Known issues for review (not fixed in r001)

- With the existing game `CARRY_OFFSET (-0.5, 0.85, 0)` applied to `carry_grip`, the pot's inner side reaches x ≈ −0.27 m. The neutral proxy's arm (radius 0.048 m at x = −0.235) occupies x ≈ −0.283…−0.187, so they overlap by about 1.3 cm (`proxy_front.png`). The manager owns the carry offset; about −0.52 m would clear this proxy.
- The design envelope gives a cavity of about 45 L to the rim, which is large for a carried water pot. Shape and size remain R pending an accepted object brief.
