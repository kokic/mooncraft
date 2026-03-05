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

Optional manifest path override:

```js
window.mcGltfEntityManifestUrl = "./assets/models/my-entities.json";
```

Runtime API (available after renderer init):

```js
// by entity id from config, or numeric index
await window.mcGltfEntityApi.setAnimation("zombie_0", "animation.zombie.walk");
await window.mcGltfEntityApi.setTexture("zombie_0", "./assets/images/entity/zombie.png");
await window.mcGltfEntityApi.setYaw("zombie_0", Math.PI * 0.5);
await window.mcGltfEntityApi.setScale("zombie_0", 1.0, 1.0, 1.0);
await window.mcGltfEntityApi.lookAtXz("zombie_0", 12, 8); // yaw only
await window.mcGltfEntityApi.lookAtXyz("zombie_0", 12, 70, 8); // yaw + pitch

// disable animation
await window.mcGltfEntityApi.setAnimation("zombie_0", "none");
```

MoonBit-side unified entity API:

- config publishing:
  - `@entity.entity_config(...)`
  - `@entity.publish_entities(entities)`
  - `@entity.clear_entities()`
- runtime controls:
  - `@entity.set_animation(id, clip)`
  - `@entity.set_texture(id, path)`
  - `@entity.set_rotation_quat(id, x, y, z, w)`
  - `@entity.set_yaw(id, yaw)`
  - `@entity.set_scale(id, x, y, z)`
  - `@entity.look_at_xz(id, x, z)`
  - `@entity.look_at_xyz(id, x, y, z)`
  - `@entity.start_animation_cycle(id, clips, interval_ms=...)`
  - `@entity.stop_animation_cycle()`
- demo entrypoint:
  - `@mob.install_default_demo(world)` (details centralized in `mob/`)
- strong typed override fields:
  - `texture_overrides : Array[@entity.TextureIndexOverride]`
  - `material_texture_overrides : Array[@entity.MaterialTextureOverride]`
- override helper constructors:
  - `@entity.texture_index_override(index, texture)`
  - `@entity.material_texture_override(material, texture)`

MoonBit typed override example:

```mbt
let cfg = @entity.entity_config(
  "zombie_skin_a",
  "./assets/models/zombie.gltf",
  texture_overrides=[@entity.texture_index_override(0, "./assets/images/entity/zombie.png")],
  material_texture_overrides=[@entity.material_texture_override("Body", "./assets/images/entity/zombie.png")],
  position=[0.0, 68.0, 0.0],
  animation="animation.zombie.walk",
)
```

Observable demo (with animation):

```mbt
// single demo entrypoint (installs zombie + rabbit demo entities)
@mob.install_default_demo(world)
```

Current implementation is aimed at Blockbench-exported glTF:

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
