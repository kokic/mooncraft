///|
pub const RABBIT_MODEL_URL : String = "./assets/models/rabbit.gltf"

///|
pub const RABBIT_TEXTURE_URL : String = "./assets/images/entity/rabbit_white.png"

///|
pub const RABBIT_Y_OFFSET : Int = 2

///|
pub fn rabbit_demo_entities(world : @level.World) -> Array[@entity.GltfEntityConfig] {
  let base_wx = @player.SPAWN_CHUNK_X * @level.CHUNK_X_SIZE + @player.SPAWN_LOCAL_X
  let base_wz = @player.SPAWN_CHUNK_Z * @level.CHUNK_Z_SIZE + @player.SPAWN_LOCAL_Z
  let rabbit_wx = base_wx + 9
  let rabbit_wz = base_wz - 1
  [
    @entity.entity_config(
      "rabbit_0",
      RABBIT_MODEL_URL,
      texture=RABBIT_TEXTURE_URL,
      position=surface_position(world, rabbit_wx, rabbit_wz, y_offset=RABBIT_Y_OFFSET),
      animation="none",
      looped=false,
    ),
  ]
}
