# Living diorama (GitHub Pages)

Static page, no build step: three.js (vendored, MIT) loads the glTF models and plays their animations.
Published to https://strata-bohemica.github.io/strata-bohemica/ by `.github/workflows/pages.yml`.

- `models/` are **web copies** of the project's own models: textures re-encoded to WebP and meshes
  compressed with meshopt (`gltf-transform webp` + `meshopt`, no geometry is removed or merged).
  They are not the source files.
- Animation is a pure function of time with a 14 s period, so every effect repeats exactly.
- Query switches for development: `?rotate=1` auto-orbit, `?exp=`, `?sun=`, `?amb=` lighting,
  `?focus=x,z,dist` close-up, `?warm=seconds` pre-simulate.
- All reconstructions are provisional. Until a licence is added, all rights are reserved.
