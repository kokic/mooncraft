///|
fn game_runtime_fixture() -> GameRuntime {
  let world = @level.World::new(seed=7U, world_type=Flat)
  let initial_chunk = world.generate_chunk(0, 0, 0)
  let chunk_runtime = @render.ChunkRuntime::new(world, initial_chunk.tile_map)
  let player_runtime = @player.PlayerRuntime::new(
    chunk_runtime.chunk_map(),
    @level.CHUNK_X_SIZE,
    world.min_y(),
    @player.PlayerInventoryRuntime::new(),
    [0.0, 65.0, 0.0],
    0.0,
    0.0,
  )
  GameRuntime::new(world, chunk_runtime, player_runtime, @level.CHUNK_X_SIZE)
}

///|
test "game runtime throttles and consumes dirty autosaves" {
  let runtime = game_runtime_fixture()
  @test.assert_eq(runtime.take_autosave(1499.0) is None, true)
  @test.assert_eq(runtime.take_autosave(1500.0) is Some(_), true)
  @test.assert_eq(runtime.take_autosave(3000.0) is None, true)
  runtime.mark_save_dirty()
  @test.assert_eq(runtime.take_autosave(3000.0) is Some(_), true)
}
