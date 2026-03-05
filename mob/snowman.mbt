///|
pub const SNOWMAN_MODEL_URL : String = "./assets/models/snowman_on.gltf"

///|
pub const SNOWMAN_TEXTURE_URL : String = "./assets/images/entity/snowman_face.png"

///|
pub fn snowman_demo_entities(world : @level.World) -> Array[@entity.GltfEntityConfig] {
  let (world_x, world_z) = zombie_0_wxz()
  let pos = surface_position(world, world_x, world_z, y_offset=RABBIT_Y_OFFSET)
  [
    @entity.entity_config(
      "snowman_0",
      SNOWMAN_MODEL_URL,
      texture=SNOWMAN_TEXTURE_URL,
      position=[pos[0] + 5, pos[1], pos[2] + 5],
      // scale=[1.0, 1.0, 1.0],
      animation="none",
      looped=false,
    ),
  ]
}
