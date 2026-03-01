///|
/// JS-facing glTF entity config consumed by `dist/js/gltf-entity-renderer.js`.
pub struct GltfEntityConfig {
  id : String
  url : String
  texture : String
  position : Array[Double]
  rotation : Array[Double]
  scale : Array[Double]
  animation : String
  speed : Double
  looped : Bool
}

///|
fn zombie_entity(
  id : String,
  x : Double,
  y : Double,
  z : Double,
  animation : String,
) -> GltfEntityConfig {
  GltfEntityConfig::{
    id,
    url: "./assets/models/zombie.gltf",
    texture: "./assets/images/entity/zombie.png",
    position: [x, y, z],
    rotation: [0.0, 0.0, 0.0, 1.0],
    scale: [1.0, 1.0, 1.0],
    animation,
    speed: 1.0,
    looped: true,
  }
}

///|
/// Default zombie demo entities loaded at startup.
pub fn zombie_demo_entities() -> Array[GltfEntityConfig] {
  [
    zombie_entity("zombie_0", 0.0, 68.0, 0.0, "animation.zombie.walk"),
    zombie_entity("zombie_1", 2.0, 68.0, 0.0, "animation.zombie.attack"),
  ]
}

///|
/// Publish entity configs to JS runtime (`window.mcGltfEntities`).
pub fn install_demo_entities() -> Unit {
  @ffi.cast_global_set("mcGltfEntities", zombie_demo_entities())
}
