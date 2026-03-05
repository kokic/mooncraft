///|
pub const ZOMBIE_MODEL_URL : String = "./assets/models/zombie.gltf"

///|
pub const ZOMBIE_TEXTURE_URL : String = "./assets/images/entity/zombie.png"

///|
pub const ZOMBIE_Y_OFFSET : Double = 2.35

///|
fn demo_spawn_base_wxz() -> (Int, Int) {
  let base_wx = @player.SPAWN_CHUNK_X * @level.CHUNK_X_SIZE + @player.SPAWN_LOCAL_X
  let base_wz = @player.SPAWN_CHUNK_Z * @level.CHUNK_Z_SIZE + @player.SPAWN_LOCAL_Z
  (base_wx, base_wz)
}

///|
fn zombie_0_wxz() -> (Int, Int) {
  let (base_wx, base_wz) = demo_spawn_base_wxz()
  (base_wx + 8, base_wz + 8)
}

///|
fn zombie_1_wxz() -> (Int, Int) {
  let (base_wx, base_wz) = demo_spawn_base_wxz()
  (base_wx + 6, base_wz + 1)
}

///|
fn surface_position(
  world : @level.World,
  wx : Int,
  wz : Int,
  y_offset? : Double = ZOMBIE_Y_OFFSET,
) -> Array[Double] {
  let y = @level.surface_height(world, wx, wz).to_double() + y_offset
  [wx.to_double() + 0.5, y, wz.to_double() + 0.5]
}

///|
pub fn zombie_demo_entities(world : @level.World) -> Array[@entity.GltfEntityConfig] {
  let (wx0, wz0) = zombie_0_wxz()
  let (wx1, wz1) = zombie_1_wxz()
  [
    @entity.entity_config(
      "zombie_0",
      ZOMBIE_MODEL_URL,
      texture=ZOMBIE_TEXTURE_URL,
      position=surface_position(world, wx0, wz0),
      animation="animation.zombie.walk",
      speed=1.0,
      looped=true,
    ),
    // @entity.entity_config(
    //   "zombie_1",
    //   ZOMBIE_MODEL_URL,
    //   texture=ZOMBIE_TEXTURE_URL,
    //   position=surface_position(world, wx1, wz1),
    //   animation="animation.zombie.attack",
    //   speed=1.0,
    //   looped=true,
    // ),
    @entity.entity_config(
      "zombie_1",
      ZOMBIE_MODEL_URL,
      texture=ZOMBIE_TEXTURE_URL,
      position=surface_position(world, wx1, wz1),
      animation="riding",
      speed=1.0,
      looped=true,
    ),
  ]
}

///|
pub fn zombie_demo_clips() -> Array[String] {
  [
    "animation.zombie.walk",
    "animation.zombie.attack",
    "riding",
    "none",
  ]
}

