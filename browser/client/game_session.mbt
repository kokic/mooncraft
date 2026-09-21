///|
/// Build the player, chunk, and game runtimes wired to the world.
fn GameRuntime::new(
  world : @level.World,
  chunk_data : Array[UInt],
  mob_runtime : @mob.MobRuntime,
) -> GameRuntime {
  let (spawn_chunk_x, spawn_chunk_z) = world.spawn_chunk_xz()
  let chunk_runtime = @chunk.ChunkRuntime::new(
    world,
    chunk_data,
    spawn_chunk_x~,
    spawn_chunk_z~,
  )
  let spawn = @player.compute_spawn_position(
    chunk_runtime.chunk_map(),
    @level.CHUNK_X_SIZE,
    @util.floor_div(world.min_y(), @level.CHUNK_X_SIZE),
    @util.floor_div(world.max_y(), @level.CHUNK_X_SIZE),
    spawn_chunk_x,
    spawn_chunk_z,
    @player.SPAWN_LOCAL_X,
    @player.SPAWN_LOCAL_Z,
    @player.SPAWN_SURFACE_OFFSET,
    @player.SPAWN_FALLBACK_Y,
  )
  let player_runtime = @player.PlayerRuntime::new(
    chunk_runtime.chunk_map(),
    @level.CHUNK_X_SIZE,
    world.min_y(),
    @player.PlayerInventoryRuntime::new(),
    spawn.position,
    @player.SPAWN_YAW,
    @player.SPAWN_PITCH,
  )
  { world, chunk_runtime, player_runtime, mob_runtime, }
}
