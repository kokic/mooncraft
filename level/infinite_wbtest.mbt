///|
fn test_top_solid_y(world : World, column : TerrainColumn) -> Int {
  for wy = world.max_y(); wy > world.min_y(); wy = wy - 1 {
    if density_at_column(world, column, wy) > 0.0 {
      return wy
    }
  }
  world.min_y()
}

///|
test "Infinite world height controls its upper boundary" {
  let short_world = World::new(
    seed=1U,
    world_type=WorldType::Infinite,
    height=INFINITE_WORLD_MIN_HEIGHT,
  )
  @test.assert_eq(short_world.height(), INFINITE_WORLD_MIN_HEIGHT)
  @test.assert_eq(short_world.min_y(), WORLD_MIN_Y)
  @test.assert_eq(short_world.max_y(), 127)

  let invalid_short_world = World::new(
    seed=1U,
    world_type=WorldType::Infinite,
    height=INFINITE_WORLD_MIN_HEIGHT - 1,
  )
  @test.assert_eq(invalid_short_world.height(), INFINITE_WORLD_MIN_HEIGHT)

  let invalid_tall_world = World::new(
    seed=1U,
    world_type=WorldType::Infinite,
    height=INFINITE_WORLD_MAX_HEIGHT + 1,
  )
  @test.assert_eq(invalid_tall_world.height(), INFINITE_WORLD_MIN_HEIGHT)
}

///|
test "Infinite surface materials use the global column surface" {
  let world = World::new(seed=7U, world_type=WorldType::Infinite)
  let column = terrain_column(world, 0, 0)
  let top = test_top_solid_y(world, column)
  let grass = @block.lookup_by_name("grass").unwrap().internal_id()
  let snow = @block.lookup_by_name("classic.snow").unwrap().internal_id()
  let dirt = @block.lookup_by_name("dirt").unwrap().internal_id()
  let sand = @block.lookup_by_name("sand").unwrap().internal_id()
  let sandstone = @block.lookup_by_name("sandstone").unwrap().internal_id()
  let surface_ids : Array[UInt] = [grass, snow, dirt, sand, sandstone]
  let min_cy = @util.floor_div(world.min_y(), CHUNK_Y_SIZE)
  let top_cy = @util.floor_div(top, CHUNK_Y_SIZE)
  for cy in min_cy..<=top_cy {
    let chunk = world.generate_chunk(0, cy, 0)
    for ry in 0..<CHUNK_Y_SIZE {
      let wy = cy * CHUNK_Y_SIZE + ry
      if wy >= world.min_y() + 5 && wy < top - 16 {
        assert_false(surface_ids.contains(chunk.get_tile(0, ry, 0)))
      }
    }
  }
  let top_chunk = world.generate_chunk(0, top_cy, 0)
  assert_true(
    surface_ids.contains(top_chunk.get_tile(0, top - top_cy * CHUNK_Y_SIZE, 0)),
  )
}

///|
test "Infinite bedrock has a solid floor and a randomized upper edge" {
  let world = World::new(seed=19U, world_type=WorldType::Infinite)
  let bedrock = @block.lookup_by_name("bedrock").unwrap().internal_id()
  let bottom_cy = @util.floor_div(world.min_y(), CHUNK_Y_SIZE)
  let chunk = world.generate_chunk(0, bottom_cy, 0)
  let mut upper_bedrock = 0
  let mut upper_non_bedrock = 0
  for wx in 0..<CHUNK_X_SIZE {
    for wz in 0..<CHUNK_Z_SIZE {
      for wy in (world.min_y() + 1)..<(world.min_y() + 5) {
        let ry = wy - bottom_cy * CHUNK_Y_SIZE
        if chunk.get_tile(wx, ry, wz) == bedrock {
          upper_bedrock = upper_bedrock + 1
        } else {
          upper_non_bedrock = upper_non_bedrock + 1
        }
      }
      let bottom_ry = world.min_y() - bottom_cy * CHUNK_Y_SIZE
      @test.assert_eq(chunk.get_tile(wx, bottom_ry, wz), bedrock)
    }
  }
  assert_true(upper_bedrock > 0)
  assert_true(upper_non_bedrock > 0)
}

///|
test "Infinite underground switches from stone to deepslate" {
  let world = World::new(seed=29U, world_type=WorldType::Infinite)
  let deepslate = @block.lookup_by_name("deepslate").unwrap().internal_id()
  let mut found = false
  for wx in 0..<CHUNK_X_SIZE {
    for wz in 0..<CHUNK_Z_SIZE {
      let column = prepare_infinite_column(world, wx, wz)
      for wy in -48..<0 {
        guard column.density_at(wy) > 0.0 else { continue }
        guard !is_infinite_bedrock(world, wx, wy, wz) else { continue }
        let cy = @util.floor_div(wy, CHUNK_Y_SIZE)
        let chunk = world.generate_chunk(0, cy, 0)
        let ry = wy - cy * CHUNK_Y_SIZE
        if chunk.get_tile(wx, ry, wz) == deepslate {
          found = true
          break
        }
      }
      guard !found else { break }
    }
    guard !found else { break }
  }
  assert_true(found)
}

///|
test "Infinite base terrain is deterministic at negative chunk coordinates" {
  let first_world = World::new(seed=23U, world_type=WorldType::Infinite)
  let second_world = World::new(seed=23U, world_type=WorldType::Infinite)
  let first = first_world.generate_chunk(-1, 0, 1)
  ignore(second_world.generate_chunk(0, 0, 1))
  let second = second_world.generate_chunk(-1, 0, 1)
  @test.assert_eq(first.tile_map, second.tile_map)
}

///|
test "Infinite density creates overhangs and underground caves" {
  let world = World::new(seed=31U, world_type=WorldType::Infinite)
  let mut has_solid_above_surface = false
  let mut has_cave_below_surface = false
  for wx in -64..<64 {
    for wz in -64..<64 {
      let column = terrain_column(world, wx, wz)
      for wy in (column.surface + 1)..<=(column.surface + TERRAIN_SHAPE_RISE) {
        if density_at_column(world, column, wy) > 0.0 {
          has_solid_above_surface = true
          break
        }
      }
      for wy in (world.min_y() + 5)..<(column.surface - 8) {
        if density_at_column(world, column, wy) <= 0.0 {
          has_cave_below_surface = true
          break
        }
      }
    }
  }
  assert_true(has_solid_above_surface)
  assert_true(has_cave_below_surface)
}

///|
test "Infinite aquifers fill some cave cells with water and deep lava" {
  let world = World::new(seed=43U, world_type=WorldType::Infinite)
  let mut has_water = false
  let mut has_lava = false
  for wx in -16..<16 {
    for wz in -16..<16 {
      let column = terrain_column(world, wx, wz)
      let top = test_top_solid_y(world, column)
      for wy in (world.min_y() + 5)..<SEA_LEVEL {
        guard wy < top - 5 else { continue }
        guard density_at_column(world, column, wy) <= 0.0 else { continue }
        match aquifer_fluid_at(world, column, wy, top) {
          Water => has_water = true
          Lava => has_lava = true
          Air => ()
        }
      }
    }
  }
  assert_true(has_water)
  assert_true(has_lava)
}

///|
test "Infinite column generation publishes only after incremental completion" {
  let world = World::new(
    seed=41U,
    world_type=WorldType::Infinite,
    height=INFINITE_WORLD_MIN_HEIGHT,
  )
  let generation = world.begin_infinite_chunk_column_generation(2, -1)
  assert_false(generation.advance(1))
  assert_true(generation.completed_chunks() is None)
  let mut iterations = 0
  while !generation.advance(8) {
    assert_true(generation.completed_chunks() is None)
    iterations += 1
    guard iterations < 128 else { abort("incremental column did not complete") }
  }
  guard generation.completed_chunks() is Some(chunks) else {
    abort("completed incremental column has no chunks")
  }
  let min_y = @util.floor_div(world.min_y(), CHUNK_Y_SIZE)
  let max_y = @util.floor_div(world.max_y(), CHUNK_Y_SIZE)
  @test.assert_eq(chunks.length(), max_y - min_y + 1)
  for index, chunk in chunks {
    @test.assert_eq(
      chunk.chunk_key(),
      chunk_key_by_chunk_xyz(2, min_y + index, -1),
    )
  }
}
