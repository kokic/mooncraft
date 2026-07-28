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
test "explicit game save restores only its matching world" {
  let source = game_runtime_fixture()
  ignore(source.execute_command("/tp 12.5 80 -4"))
  let save_text = source.save_snapshot(1500.0)

  let restored = game_runtime_fixture()
  load_initial_save(restored, restored.world, save_text)
  @test.assert_eq(restored.player_runtime.position(), [12.5, 80.0, -4.0])

  let mismatched = game_runtime_fixture()
  let other_world = @level.World::new(seed=8U, world_type=Flat)
  load_initial_save(mismatched, other_world, save_text)
  @test.assert_eq(mismatched.player_runtime.position(), [0.0, 65.0, 0.0])

  let new_world = game_runtime_fixture()
  load_initial_save(new_world, new_world.world, "")
  @test.assert_eq(new_world.player_runtime.position(), [0.0, 65.0, 0.0])
}

///|
test "game runtime executes teleport command" {
  let runtime = game_runtime_fixture()
  let result = runtime.execute_command("/tp 12.5 80 -4")
  @test.assert_eq(result.success, true)
  @test.assert_eq(runtime.player_runtime.position(), [12.5, 80.0, -4.0])
}

///|
test "game runtime executes render distance command" {
  let runtime = game_runtime_fixture()
  let result = runtime.execute_command("/rd 6")
  @test.assert_eq(result.success, true)
  @test.assert_eq(runtime.chunk_runtime.render_distance(), 6)
}

///|
test "game runtime rejects invalid commands without changing state" {
  let runtime = game_runtime_fixture()
  let initial_position = runtime.player_runtime.position()
  let initial_distance = runtime.chunk_runtime.render_distance()
  let invalid_distance = @render.MAX_RENDER_DISTANCE + 1
  for
    command in [
      "/tp 1 2",
      "/tp NaN 2 3",
      "/rd -1",
      "/rd \{invalid_distance}",
      "/unknown",
    ] {
    let result = runtime.execute_command(command)
    @test.assert_eq(result.success, false)
  }
  @test.assert_eq(runtime.player_runtime.position(), initial_position)
  @test.assert_eq(runtime.chunk_runtime.render_distance(), initial_distance)
}
