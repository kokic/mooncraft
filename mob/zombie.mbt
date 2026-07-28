///|
pub const ZOMBIE_MODEL_URL : String = "./assets/models/zombie.gltf"

///|
pub const ZOMBIE_TEXTURE_URL : String = "./assets/images/entity/zombie.png"

///|
const ZOMBIE_0_ID : String = "zombie_0"

///|
pub const ZOMBIE_Y_OFFSET : Double = 2.35

///|
const ZOMBIE_FEET_SURFACE_OFFSET : Double = 1.0

///|
const ZOMBIE_RENDER_Y_OFFSET : Double = ZOMBIE_Y_OFFSET -
  ZOMBIE_FEET_SURFACE_OFFSET

///|
fn demo_spawn_base_wxz() -> (Int, Int) {
  let base_wx = @player.SPAWN_CHUNK_X * @level.CHUNK_X_SIZE +
    @player.SPAWN_LOCAL_X
  let base_wz = @player.SPAWN_CHUNK_Z * @level.CHUNK_Z_SIZE +
    @player.SPAWN_LOCAL_Z
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
pub struct ZombieSpawn {
  id : String
  position : @entity.EntityPosition
  animation : String
}

///|
pub fn zombie_spawn(
  world : @level.World,
  id : String,
  wx : Int,
  wz : Int,
  animation : String,
) -> ZombieSpawn {
  let feet_y = @level.surface_height(world, wx, wz).to_double() +
    ZOMBIE_FEET_SURFACE_OFFSET
  {
    id,
    position: @entity.EntityPosition::new(
      wx.to_double() + 0.5,
      feet_y,
      wz.to_double() + 0.5,
    ),
    animation,
  }
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
fn zombie_spawns(world : @level.World) -> Array[ZombieSpawn] {
  let (wx0, wz0) = zombie_0_wxz()
  let (wx1, wz1) = zombie_1_wxz()
  [
    zombie_spawn(world, ZOMBIE_0_ID, wx0, wz0, "none"),
    zombie_spawn(world, "zombie_1", wx1, wz1, "riding"),
  ]
}

///|
fn ZombieSpawn::render_config(self : ZombieSpawn) -> @render.GltfEntityConfig {
  @render.entity_config(
    self.id,
    ZOMBIE_MODEL_URL,
    texture=ZOMBIE_TEXTURE_URL,
    position=[
      self.position.x,
      self.position.y + ZOMBIE_RENDER_Y_OFFSET,
      self.position.z,
    ],
    animation=self.animation,
    speed=1.0,
    looped=true,
  )
}

///|
fn zombie_demo_entities(
  world : @level.World,
) -> Array[@render.GltfEntityConfig] {
  // STATUS: NEEDS_ADJUSTMENT - demo placement and clip choices are hard-coded
  // so model/animation coverage can be inspected before gameplay logic exists.
  zombie_spawns(world).map(spawn => spawn.render_config())
}
