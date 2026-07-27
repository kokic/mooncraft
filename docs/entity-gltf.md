# Entity glTF (experimental)

Entity models can be loaded via `dist/assets/models/entities.json` manifest or injected at runtime through the JS bridge. The manifest supports per-entity id, model url, texture, per-material texture overrides, position, rotation, scale, animation clip, speed, and loop flag.

MoonBit-side API covers entity config definition, publishing, clearing, and runtime controls for animation, texture, rotation, yaw, scale, and look-at direction. A demo entrypoint installs default entities.

Current implementation targets Blockbench-exported glTF:

- MoonBit owns entity instances, animation state, draw scheduling, glTF parsing,
  accessor decoding, shader/program creation, and GPU primitive construction;
  JS only supplies browser resource loading and the WebGL context
- the primitive FFI accepts ordinary `Float32Array` values; missing normals,
  UVs, or indices cross the boundary as an empty array, never as a MoonBit
  `Option` representation
- new worlds use the MoonBit-owned player spawn yaw and pitch, aimed toward the
  demo entity area; loaded worlds restore their saved camera orientation

- static mesh nodes
- node TRS animation channels (`translation` / `rotation` / `scale`)
- `STEP` / `LINEAR` interpolation
- `CUBICSPLINE` is currently downgraded to value-key linear blending
- `.gltf` (external textures) and `.glb` (embedded image bufferView) texture loading
- entity textures default to `NEAREST` sampling (gltf sampler can override)
- if a model has no embedded texture reference, specify `texture`, `textures`,
  or `materialTextures` in config explicitly
- `materialTextures` supports material-name overrides (recommended for multi-skin assets)
- entities missing both embedded texture and config texture are skipped
- `textures` supports material-index overrides (array or object map); object
  keys that are not numeric are treated as material names
- `animation: false` or `animation: "none"` disables clip autoplay
