///|
fn design_chunk_map() -> @hashmap.HashMap[String, Array[UInt]] {
  let world = @level.World::new(
    seed=1U,
    world_type=@level.WorldType::Design,
  )
  let map : @hashmap.HashMap[String, Array[UInt]] = @hashmap.HashMap([])
  let min_y = world.min_y()
  let max_y = world.max_y()
  for cz in -4..<4 {
    for cx in -4..<4 {
      let chunks = world.generate_chunk_column(cx, cz)
      for chunk in chunks {
        if chunk.y >= @util.floor_div(min_y, @level.CHUNK_Y_SIZE) &&
          chunk.y <= @util.floor_div(max_y, @level.CHUNK_Y_SIZE) {
          map[chunk.chunk_key()] = chunk.tile_map
        }
      }
    }
  }
  map
}

///|
test "capture extracts placed blocks above the grass floor" {
  let map = design_chunk_map()
  let stone_id = @block.lookup_by_name("stone").unwrap().internal_id()
  let water_id = @block.lookup_by_name("water").unwrap().internal_id()
  ignore(@level.set_block_id(map, @level.CHUNK_X_SIZE, 0, 0, 0, stone_id))
  ignore(@level.set_block_id(map, @level.CHUNK_X_SIZE, 0, 1, 0, water_id))
  let bp = capture_design_world(
    map,
    @level.CHUNK_X_SIZE,
    -1,
    -1,
    -1,
    1,
    2,
    1,
    @level.DESIGN_MIN_Y,
  )
  @test.assert_eq(bp.width(), 1)
  @test.assert_eq(bp.height(), 2)
  @test.assert_eq(bp.depth(), 1)
  @test.assert_eq(bp.cell(0, 0, 0), 0)
  @test.assert_eq(bp.cell(0, 1, 0), 1)
  @test.assert_eq(bp.palette.length(), 2)
  @test.assert_eq(bp.palette[0], "stone")
  @test.assert_eq(bp.palette[1], "water")
}

///|
test "capture decodes block state into palette suffix" {
  let map = design_chunk_map()
  let log_id = @block.lookup_by_name("classic.oak_log")
    .unwrap()
    .internal_id(state=1)
  ignore(@level.set_block_id(map, @level.CHUNK_X_SIZE, 0, 1, 0, log_id))
  let bp = capture_design_world(
    map,
    @level.CHUNK_X_SIZE,
    0,
    0,
    0,
    0,
    2,
    0,
    @level.DESIGN_MIN_Y,
  )
  @test.assert_eq(bp.palette.length(), 1)
  @test.assert_eq(bp.palette[0], "classic.oak_log:1")
  let placed = load_blueprint_into_world(map, @level.CHUNK_X_SIZE, bp.encode(), 5, 5, 5)
  @test.assert_eq(placed, Ok(()))
  let back = @level.get_block_id(map, @level.CHUNK_X_SIZE, 5, 5, 5).unwrap()
  @test.assert_eq(back, log_id)
}

///|
test "load_blueprint_into_world places at the requested anchor" {
  let map = design_chunk_map()
  let bp = @designer.Blueprint::new(
    "box",
    [2, 1, 1],
    [1, 0, 0],
    palette=["stone"],
  )
  bp.set_cell(0, 0, 0, 0)
  bp.set_cell(1, 0, 0, 0)
  let result = load_blueprint_into_world(map, @level.CHUNK_X_SIZE, bp.encode(), 10, 20, 30)
  @test.assert_eq(result, Ok(()))
  let stone_id = @block.lookup_by_name("stone").unwrap().internal_id()
  // Anchor (1,0,0) lands on (10,20,30); local x=0 lands one behind it.
  @test.assert_eq(
    @level.get_block_id(map, @level.CHUNK_X_SIZE, 9, 20, 30).unwrap(),
    stone_id,
  )
  @test.assert_eq(
    @level.get_block_id(map, @level.CHUNK_X_SIZE, 10, 20, 30).unwrap(),
    stone_id,
  )
}

///|
test "capture trims surrounding air and keeps ground-free bounds" {
  let map = design_chunk_map()
  let stone_id = @block.lookup_by_name("stone").unwrap().internal_id()
  ignore(@level.set_block_id(map, @level.CHUNK_X_SIZE, 4, 1, 4, stone_id))
  let bp = capture_design_world(
    map,
    @level.CHUNK_X_SIZE,
    -8,
    -1,
    -8,
    8,
    3,
    8,
    @level.DESIGN_MIN_Y,
  )
  @test.assert_eq(bp.width(), 1)
  @test.assert_eq(bp.height(), 1)
  @test.assert_eq(bp.depth(), 1)
  @test.assert_eq(bp.anchor[0], 0)
  @test.assert_eq(bp.anchor[1], 0)
  @test.assert_eq(bp.anchor[2], 0)
  @test.assert_eq(bp.cell(0, 0, 0), 0)
}
