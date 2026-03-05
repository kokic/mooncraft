///|
pub const RABBIT_MODEL_URL : String = "./assets/models/rabbit.gltf"

///|
pub const RABBIT_TEXTURE_URL : String = "./assets/images/entity/rabbit_white.png"

///|
pub const RABBIT_Y_BELOW_ZOMBIE : Double = 2.4

///|
pub const RABBIT_Y_OFFSET : Double = ZOMBIE_Y_OFFSET - RABBIT_Y_BELOW_ZOMBIE

///|
pub fn rabbit_demo_entities(world : @level.World) -> Array[@entity.GltfEntityConfig] {
  let (rabbit_wx, rabbit_wz) = zombie_1_wxz()
  let pos = surface_position(world, rabbit_wx, rabbit_wz, y_offset=RABBIT_Y_OFFSET)
  [
    @entity.entity_config(
      "rabbit_0",
      RABBIT_MODEL_URL,
      texture=RABBIT_TEXTURE_URL,
      position=[pos[0], pos[1], pos[2] - 1.25],
      scale=[4.0, 4.0, 4.0],
      animation="none",
      looped=false,
    ),
  ]
}
