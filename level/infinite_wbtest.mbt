///|
test "Infinite surface materials use the global column surface" {
  let world = World::new(seed=7U, world_type=WorldType::Infinite)
  let column = terrain_column(world, 0, 0)
  let top = top_solid_y(world, column)
  let grass = @block.lookup_by_name("grass").unwrap().id
  let snow = @block.lookup_by_name("classic.snow").unwrap().id
  let dirt = @block.lookup_by_name("dirt").unwrap().id
  let sand = @block.lookup_by_name("sand").unwrap().id
  let sandstone = @block.lookup_by_name("sandstone").unwrap().id
  let surface_ids : Array[UInt] = [grass, snow, dirt, sand, sandstone]
  let min_cy = @util.floor_div(WORLD_MIN_Y, CHUNK_Y_SIZE)
  let top_cy = @util.floor_div(top, CHUNK_Y_SIZE)
  for cy in min_cy..<=top_cy {
    let chunk = world.generate_chunk(0, cy, 0)
    for ry in 0..<CHUNK_Y_SIZE {
      let wy = cy * CHUNK_Y_SIZE + ry
      if wy >= WORLD_MIN_Y + 5 && wy < top - 16 {
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
test "Infinite bedrock is a deterministic contiguous variable layer" {
  let world = World::new(seed=19U, world_type=WorldType::Infinite)
  let bedrock = @block.lookup_by_name("bedrock").unwrap().id
  let bottom_cy = @util.floor_div(WORLD_MIN_Y, CHUNK_Y_SIZE)
  let chunk = world.generate_chunk(0, bottom_cy, 0)
  let mut min_depth = 6
  let mut max_depth = 0
  for wx in 0..<CHUNK_X_SIZE {
    for wz in 0..<CHUNK_Z_SIZE {
      let mut depth = 0
      for wy in WORLD_MIN_Y..<(WORLD_MIN_Y + 5) {
        let ry = wy - bottom_cy * CHUNK_Y_SIZE
        if chunk.get_tile(wx, ry, wz) == bedrock {
          depth = depth + 1
        } else {
          break
        }
      }
      let bottom_ry = WORLD_MIN_Y - bottom_cy * CHUNK_Y_SIZE
      @test.assert_eq(chunk.get_tile(wx, bottom_ry, wz), bedrock)
      assert_true(depth >= 1 && depth <= 5)
      if depth < min_depth {
        min_depth = depth
      }
      if depth > max_depth {
        max_depth = depth
      }
    }
  }
  assert_true(min_depth < max_depth)
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
      for wy in (WORLD_MIN_Y + 5)..<(column.surface - 8) {
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
      let top = top_solid_y(world, column)
      for wy in (WORLD_MIN_Y + 5)..<SEA_LEVEL {
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
