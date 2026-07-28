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
test "game save includes spawned entities" {
  @mob.reset_entities()
  assert_true(
    @mob.spawn(
      @mob.MobSpawnRequest::new("saved_zombie", Zombie, 4.0, 65.0, -2.0),
    ),
  )
  let saved = game_runtime_fixture().save_snapshot(1500.0)
  @mob.reset_entities()

  guard @save.decode_save_payload(saved) is Some(payload) else {
    fail("expected entity save payload")
  }
  guard payload.entities() is [entity] else { fail("expected saved entity") }
  @test.assert_eq(entity.id, "saved_zombie")
  guard entity.kind is Mob(Zombie) else { fail("expected saved zombie") }
  @test.assert_eq(entity.position.x, 4.0)
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
test "summon command accepts supported entities and defaults animation" {
  match parse_command("/summon zombie") {
    Summon(Zombie, "none") => ()
    _ => fail("zombie summon did not use the default animation")
  }
  match parse_command("/summon rabbit hop") {
    Summon(Rabbit, "hop") => ()
    _ => fail("rabbit summon did not preserve its animation")
  }
  match parse_command("/summon snowman") {
    Summon(Snowman, "none") => ()
    _ => fail("snowman summon was not accepted")
  }
}

///|
test "build command accepts supported structures" {
  match parse_command("/build oak") {
    Build(Oak) => ()
    _ => fail("oak build was not accepted")
  }
  match parse_command("/build fallen_oak") {
    Build(FallenOak) => ()
    _ => fail("fallen oak build was not accepted")
  }
  match parse_command("/build cactus") {
    Build(Cactus) => ()
    _ => fail("cactus build was not accepted")
  }
  match parse_command("/build nether_spire") {
    Build(NetherSpire) => ()
    _ => fail("nether spire build was not accepted")
  }
}

///|
test "game runtime builds an oak at the crosshair target" {
  let runtime = game_runtime_fixture()
  ignore(runtime.player_runtime.restore([8.5, 4.0, 8.5], 0.0, -1.0))
  let result = runtime.execute_command("/build oak")
  @test.assert_eq(result.success, true)
  assert_true(runtime.chunk_runtime.block_deltas().length() > 0)
}

///|
test "game runtime summons a zombie at the crosshair target" {
  let runtime = game_runtime_fixture()
  ignore(runtime.player_runtime.restore([0.5, 4.0, 0.5], 0.0, -1.0))
  let result = runtime.execute_command("/summon zombie")
  @test.assert_eq(result.success, true)
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
      "/summon skeleton",
      "/summon zombie idle extra",
      "/build acacia",
      "/build oak extra",
      "/unknown",
    ] {
    let result = runtime.execute_command(command)
    @test.assert_eq(result.success, false)
  }
  @test.assert_eq(runtime.player_runtime.position(), initial_position)
  @test.assert_eq(runtime.chunk_runtime.render_distance(), initial_distance)
}
