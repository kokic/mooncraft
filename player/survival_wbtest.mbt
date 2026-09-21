///|
fn flat_test_map() -> @hashmap.HashMap[String, Array[UInt]] {
  let map : @hashmap.HashMap[String, Array[UInt]] = @hashmap.HashMap([])
  let chunk = @level.Chunk::new(0, 0, 0)
  let stone = @block.name_to_internal_id("stone")
  for rx in 0..<16 {
    for rz in 0..<16 {
      chunk.update_tile_map(rx, 0, rz, stone)
    }
  }
  map[@level.chunk_key_by_chunk_xyz(0, 0, 0)] = chunk.tile_map
  map
}

///|
fn survival_runtime(y : Double) -> PlayerRuntime {
  PlayerRuntime::new(
    flat_test_map(),
    16,
    -64,
    PlayerInventoryRuntime::new(game_mode="survival"),
    [8.0, y, 8.0],
    0.0,
    0.0,
  )
}

///|
fn calm_context(game_mode? : String = "survival") -> VitalsContext {
  {
    game_mode,
    moved: false,
    sprinted: false,
    jumped: false,
    on_ground: true,
    fall_distance: 0.0,
    head_in_water: false,
    in_lava: false,
    on_cactus: false,
    below_world: false,
  }
}

///|
test "gravity settles the player on the floor" {
  let runtime = survival_runtime(6.0)
  for _i in 0..<200 {
    ignore(runtime.tick(1.0 / 60.0))
  }
  let snapshot = runtime.snapshot()
  assert_true(snapshot.on_ground)
  assert_true(snapshot.position[1] > 0.99)
  assert_true(snapshot.position[1] < 1.1)
}

///|
test "jump leaves the ground with upward velocity" {
  let runtime = survival_runtime(6.0)
  for _i in 0..<200 {
    ignore(runtime.tick(1.0 / 60.0))
  }
  runtime.set_move_intent(MoveInput::new(up=true))
  let snapshot = runtime.tick(1.0 / 60.0)
  assert_true(snapshot.velocity_y > 0.0)
  assert_true(snapshot.position[1] > 1.0)
}

///|
test "a fall damages the player on landing" {
  let runtime = survival_runtime(10.0)
  for _i in 0..<200 {
    ignore(runtime.tick(1.0 / 60.0))
  }
  let snapshot = runtime.snapshot()
  assert_true(snapshot.health < MAX_HEALTH)
  assert_false(snapshot.dead)
}

///|
test "death and respawn restore a full healthy state" {
  let runtime = survival_runtime(5.0)
  let dead = runtime.kill()
  assert_true(dead.dead)
  @test.assert_eq(dead.health, 0.0)
  let respawned = runtime.respawn()
  assert_false(respawned.dead)
  @test.assert_eq(respawned.health, MAX_HEALTH)
  @test.assert_eq(respawned.position, [8.0, 5.0, 8.0])
}

///|
test "discrete hits respect the invulnerability window" {
  let first = Vitals::full().apply_hit(5.0)
  @test.assert_eq(first.health, 15.0)
  let during = first.apply_hit(5.0)
  @test.assert_eq(during.health, 15.0)
  let after = { ..during, hunger: 16.0, }.tick(calm_context(), 0.6)
  let next = after.apply_hit(4.0)
  @test.assert_eq(next.health, 11.0)
}

///|
test "breath drains underwater and drowning damages the player" {
  let underwater = { ..calm_context(), head_in_water: true, }
  let mut vitals = Vitals::full()
  for _i in 0..<60 {
    vitals = vitals.tick(underwater, 0.25)
  }
  @test.assert_eq(vitals.air, 0.0)
  assert_true(vitals.health < MAX_HEALTH)
}

///|
test "well fed players regenerate and starving players lose health" {
  let fed = { ..Vitals::full(), health: 10.0, }
  let regenerated = fed.tick(calm_context(), 1.0)
  assert_true(regenerated.health > 10.0)
  let starving = { ..Vitals::full(), hunger: 0.0, }
  let weakened = starving.tick(calm_context(), 4.0)
  assert_true(weakened.health < MAX_HEALTH)
}

///|
test "eating restores hunger and saturation" {
  let hungry = { ..Vitals::full(), hunger: 10.0, saturation: 0.0, }
  let fed = hungry.eat(4.0, 2.4)
  @test.assert_eq(fed.hunger, 14.0)
  @test.assert_eq(fed.saturation, 2.4)
  @test.assert_eq(Vitals::full().eat(4.0, 2.4).hunger, MAX_HUNGER)
}

///|
test "creative flight hovers and ascends" {
  let runtime = PlayerRuntime::new(
    flat_test_map(),
    16,
    -64,
    PlayerInventoryRuntime::new(game_mode="creative"),
    [8.0, 10.0, 8.0],
    0.0,
    0.0,
  )
  let toggled = runtime.toggle_flight()
  assert_true(toggled.flying)
  for _i in 0..<60 {
    ignore(runtime.tick(1.0 / 60.0))
  }
  let hovering = runtime.snapshot()
  assert_true(hovering.position[1] > 9.9)
  assert_true(hovering.position[1] < 10.1)
  runtime.set_move_intent(MoveInput::new(up=true))
  let ascending = runtime.tick(1.0 / 60.0)
  assert_true(ascending.position[1] > hovering.position[1])
}

///|
test "survival mode ignores the flight toggle" {
  let runtime = survival_runtime(10.0)
  let snapshot = runtime.toggle_flight()
  assert_false(snapshot.flying)
}

///|
test "creative players take no environmental damage" {
  let lava = { ..calm_context(game_mode="creative"), in_lava: true, }
  let vitals = Vitals::full().tick(lava, 10.0)
  @test.assert_eq(vitals.health, MAX_HEALTH)
  @test.assert_eq(vitals.air, MAX_AIR)
}
