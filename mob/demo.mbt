///|
const ZOMBIE_0_ID : String = "zombie_0"

///|
fn demo_spawn_base_xz() -> (Int, Int) {
  let base_x = @player.SPAWN_CHUNK_X * @level.CHUNK_X_SIZE +
    @player.SPAWN_LOCAL_X
  let base_z = @player.SPAWN_CHUNK_Z * @level.CHUNK_Z_SIZE +
    @player.SPAWN_LOCAL_Z
  (base_x, base_z)
}

///|
fn demo_position(
  world : @level.World,
  x : Double,
  z : Double,
) -> (Double, Double, Double) {
  let surface_y = @level.surface_height(
    world,
    x.floor().to_int(),
    z.floor().to_int(),
  )
  (x, surface_y.to_double() + 1.0, z)
}

///|
fn default_demo_requests(world : @level.World) -> Array[MobSpawnRequest] {
  let (base_x, base_z) = demo_spawn_base_xz()
  let (zombie_0_x, zombie_0_y, zombie_0_z) = demo_position(
    world,
    (base_x + 8).to_double() + 0.5,
    (base_z + 8).to_double() + 0.5,
  )
  let (zombie_1_x, zombie_1_y, zombie_1_z) = demo_position(
    world,
    (base_x + 6).to_double() + 0.5,
    (base_z + 1).to_double() + 0.5,
  )
  let (rabbit_x, rabbit_y, rabbit_z) = demo_position(
    world,
    (base_x + 6).to_double() + 0.5,
    (base_z + 1).to_double() - 0.75,
  )
  let (snowman_x, snowman_y, snowman_z) = demo_position(
    world,
    (base_x + 8).to_double() + 5.5,
    (base_z + 8).to_double() + 5.5,
  )
  [
    MobSpawnRequest::new(
      ZOMBIE_0_ID,
      Zombie,
      zombie_0_x,
      zombie_0_y,
      zombie_0_z,
      zombie_spec().scale,
    ),
    MobSpawnRequest::new(
      "zombie_1",
      Zombie,
      zombie_1_x,
      zombie_1_y,
      zombie_1_z,
      animation="riding",
      zombie_spec().scale,
    ),
    MobSpawnRequest::new(
      "rabbit_0",
      Rabbit,
      rabbit_x,
      rabbit_y,
      rabbit_z,
      rabbit_spec().scale,
    ),
    MobSpawnRequest::new(
      "snowman_0",
      Snowman,
      snowman_x,
      snowman_y,
      snowman_z,
      snowman_spec().scale,
    ),
  ]
}

///|
pub fn MobRuntime::install_default_demo(
  self : MobRuntime,
  world : @level.World,
) -> Unit {
  for request in default_demo_requests(world) {
    ignore(self.spawn(request))
  }
}
