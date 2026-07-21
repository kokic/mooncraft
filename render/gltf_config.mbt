///|
/// Texture override for one material index.
pub struct TextureIndexOverride {
  index : Int
  texture : String
}

///|
/// Texture override for one material name.
pub struct MaterialTextureOverride {
  material : String
  texture : String
}

///|
pub fn texture_index_override(
  index : Int,
  texture : String,
) -> TextureIndexOverride {
  TextureIndexOverride::{ index, texture }
}

///|
pub fn material_texture_override(
  material : String,
  texture : String,
) -> MaterialTextureOverride {
  MaterialTextureOverride::{ material, texture }
}

///|
/// JS-facing glTF entity config consumed by `dist/js/gltf-entity-renderer.js`.
pub struct GltfEntityConfig {
  id : String
  url : String
  texture : String
  texture_overrides : Array[TextureIndexOverride]
  material_texture_overrides : Array[MaterialTextureOverride]
  position : Array[Double]
  rotation : Array[Double]
  scale : Array[Double]
  animation : String
  speed : Double
  looped : Bool
}

///|
pub fn entity_config(
  id : String,
  url : String,
  texture? : String = "",
  texture_overrides? : Array[TextureIndexOverride] = [],
  material_texture_overrides? : Array[MaterialTextureOverride] = [],
  position? : Array[Double] = [0.0, 0.0, 0.0],
  rotation? : Array[Double] = [0.0, 0.0, 0.0, 1.0],
  scale? : Array[Double] = [1.0, 1.0, 1.0],
  animation? : String = "",
  speed? : Double = 1.0,
  looped? : Bool = true,
) -> GltfEntityConfig {
  GltfEntityConfig::{
    id,
    url,
    texture,
    texture_overrides,
    material_texture_overrides,
    position,
    rotation,
    scale,
    animation,
    speed,
    looped,
  }
}

///|
/// Publish explicit entity configs to JS runtime (`window.mcGltfEntities`).
pub fn publish_entities(entities : Array[GltfEntityConfig]) -> Unit {
  @ffi.cast_global_set("mcGltfEntities", entities)
}

///|
pub fn clear_entities() -> Unit {
  publish_entities([])
}
