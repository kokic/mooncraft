# Entity glTF (experimental)

You can load entity models by providing `dist/assets/models/entities.json`:

```json
[
  {
    "id": "pig_0",
    "url": "./assets/models/pig.gltf",
    "texture": "./assets/images/entity/pig.png",
    "materialTextures": {
      "Body": "./assets/images/entity/pig.png"
    },
    "position": [8, 70, 8],
    "rotation": [0, 0, 0, 1],
    "scale": [1, 1, 1],
    "animation": "Walk",
    "speed": 1.0,
    "loop": true
  }
]
```

You can also bypass the manifest and inject at runtime:

```js
window.mcGltfEntities = [
  {
    url: "./assets/models/zombie.gltf",
    texture: "./assets/images/entity/zombie.png",
    animation: "animation.zombie.walk",
    position: [0, 68, 0],
  },
];
```

Runtime API (available after renderer init):

```js
// by entity id from config, or numeric index
window.mcGltfEntityApi.setAnimation("zombie_0", "animation.zombie.walk");
window.mcGltfEntityApi.setTexture("zombie_0", "./assets/images/entity/zombie.png");
window.mcGltfEntityApi.setYaw("zombie_0", Math.PI * 0.5);
window.mcGltfEntityApi.setScale("zombie_0", 1.0, 1.0, 1.0);
window.mcGltfEntityApi.lookAtXz("zombie_0", 12, 8); // yaw only
window.mcGltfEntityApi.lookAtXyz("zombie_0", 12, 70, 8); // yaw + pitch

// disable animation
window.mcGltfEntityApi.setAnimation("zombie_0", "none");
```

MoonBit-side unified entity API:

- config publishing:
  - `@render.entity_config(...)`
  - `@render.publish_entities(entities)`
  - `@render.clear_entities()`
- runtime controls:
  - `@render.set_animation(id, clip)`
  - `@render.set_texture(id, path)`
  - `@render.set_rotation_quat(id, x, y, z, w)`
  - `@render.set_yaw(id, yaw)`
  - `@render.set_scale(id, x, y, z)`
  - `@render.look_at_xz(id, x, z)`
  - `@render.look_at_xyz(id, x, y, z)`
  - `@render.start_animation_cycle(id, clips, interval_ms=...)`
  - `@render.stop_animation_cycle()`
- demo entrypoint:
  - `@mob.install_default_demo(world)` (details centralized in `mob/`)
- strong typed override fields:
  - `texture_overrides : Array[@render.TextureIndexOverride]`
  - `material_texture_overrides : Array[@render.MaterialTextureOverride]`
- override helper constructors:
  - `@render.texture_index_override(index, texture)`
  - `@render.material_texture_override(material, texture)`

MoonBit typed override example:

```mbt
let cfg = @render.entity_config(
  "zombie_skin_a",
  "./assets/models/zombie.gltf",
  texture_overrides=[@render.texture_index_override(0, "./assets/images/entity/zombie.png")],
  material_texture_overrides=[@render.material_texture_override("Body", "./assets/images/entity/zombie.png")],
  position=[0.0, 68.0, 0.0],
  animation="animation.zombie.walk",
)
```

Observable demo (with animation):

```mbt
// single demo entrypoint (installs the current zombie demo entities)
@mob.install_default_demo(world)
```

Current implementation is aimed at Blockbench-exported glTF:

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
  or `materialTextures`
  in config explicitly
- `materialTextures` supports material-name overrides (recommended for multi-skin assets)
- entities missing both embedded texture and config texture are skipped
- `textures` supports material-index overrides (array or object map); object
  keys that are not numeric are treated as material names
- `animation: false` or `animation: "none"` disables clip autoplay
- runtime API:
  - `setAnimation(entityId, clip)`
  - `setTexture(entityId, path)`
  - `setYaw(entityId, yaw)`
  - `setScale(entityId, x, y, z)`
  - `lookAtXz(entityId, x, z)`
  - `lookAtXyz(entityId, x, y, z)`
