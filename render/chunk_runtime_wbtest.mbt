///|
test "chunk runtime owns section invalidation" {
  let world = @level.World::new(seed=1U, world_type=@level.WorldType::Flat)
  let initial = world.generate_chunk(0, 0, 0).tile_map
  let runtime = ChunkRuntime::new(
    world,
    initial,
    render_distance=0,
    generation_budget=1,
  )
  let registry = BlockRegistry::create([], [])
  let initial_frame = runtime.tick(registry, 0, 0)
  assert_true(initial_frame.mesh_updates.length() > 0)
  @test.assert_eq(initial_frame.recolors.length(), 0)
  for command in initial_frame.mesh_updates {
    @test.assert_eq(command.mesh.normal.normals.length(), 0)
    @test.assert_eq(command.mesh.leaf.normals.length(), 0)
    @test.assert_eq(command.mesh.water.normals.length(), 0)
    @test.assert_eq(command.mesh.translucent.normals.length(), 0)
  }
  let stone = @block.lookup_by_name("stone").unwrap().id
  assert_true(runtime.set_block(1, 1, 1, stone))
  let mut rebuild_seen = false
  for _ in 0..<16 {
    let frame = runtime.tick(registry, 0, 0)
    @test.assert_eq(frame.recolors.length(), 0)
    let section = frame.mesh_updates.any(command => command.chunk_key == "0,0,0")
    if section {
      rebuild_seen = true
      break
    }
  }
  assert_true(rebuild_seen)
  @test.assert_eq(runtime.block_deltas().length(), 1)
}

///|
test "chunk runtime applies structures atomically to loaded chunks" {
  let world = @level.World::new(seed=2U, world_type=@level.WorldType::Flat)
  let initial = world.generate_chunk(0, 0, 0).tile_map
  let runtime = ChunkRuntime::new(world, initial, render_distance=0)
  let stone = @block.lookup_by_name("stone").unwrap().id
  let partial = [
    @level.BlockDelta::new(1, 5, 1, "stone"),
    @level.BlockDelta::new(16, 5, 1, "stone"),
  ]

  assert_false(runtime.apply_block_deltas(partial))
  @test.assert_eq(
    @level.get_block_id(runtime.chunk_map(), @level.CHUNK_X_SIZE, 1, 5, 1),
    Some(@schema.AIR_ID),
  )
  @test.assert_eq(runtime.block_deltas().length(), 0)

  let structure = [
    @level.BlockDelta::new(1, 5, 1, "stone"),
    @level.BlockDelta::new(2, 5, 1, "stone"),
  ]
  assert_true(runtime.apply_block_deltas(structure))
  @test.assert_eq(
    @level.get_block_id(runtime.chunk_map(), @level.CHUNK_X_SIZE, 1, 5, 1),
    Some(stone),
  )
  @test.assert_eq(
    @level.get_block_id(runtime.chunk_map(), @level.CHUNK_X_SIZE, 2, 5, 1),
    Some(stone),
  )
  @test.assert_eq(runtime.block_deltas().length(), 2)
}

///|
test "chunk runtime meshes dirty sections from the center outward" {
  let world = @level.World::new(seed=3U, world_type=@level.WorldType::Flat)
  let initial = world.generate_chunk(0, 0, 0).tile_map
  let runtime = ChunkRuntime::new(
    world,
    initial,
    render_distance=1,
    mesh_budget=1,
  )
  for key in runtime.dirty_sections.keys().to_array() {
    runtime.dirty_sections.remove(key)
  }
  runtime.refresh_desired(0, 0)
  let center_chunk_key = @level.chunk_key_by_chunk_xyz(0, 0, 0)
  let outer_chunk_key = @level.chunk_key_by_chunk_xyz(1, 0, 0)
  let center = ChunkSection::{ chunk_key: center_chunk_key, x: 0, y: 0, z: 0 }
  let outer = ChunkSection::{ chunk_key: outer_chunk_key, x: 0, y: 0, z: 0 }
  runtime.dirty_sections[section_key(outer_chunk_key, 0, 0, 0)] = outer
  runtime.dirty_sections[section_key(center_chunk_key, 0, 0, 0)] = center

  let sections = runtime.take_dirty_sections()

  @test.assert_eq(sections.length(), 1)
  @test.assert_eq(sections[0].chunk_key, center_chunk_key)
}

///|
test "chunk runtime streams complete columns" {
  let world = @level.World::new(seed=2U, world_type=@level.WorldType::Flat)
  let initial = world.generate_chunk(0, 0, 0).tile_map
  let runtime = ChunkRuntime::new(
    world,
    initial,
    render_distance=0,
    generation_budget=1,
    mesh_budget=1,
  )
  let registry = BlockRegistry::create([], [])
  ignore(runtime.tick(registry, 0, 0))
  let frame = runtime.tick(registry, 1, 0)
  let min_y = @util.floor_div(world.min_y(), @level.CHUNK_Y_SIZE)
  let max_y = @util.floor_div(world.max_y(), @level.CHUNK_Y_SIZE)
  let column_height = max_y - min_y + 1
  @test.assert_eq(frame.generated.length(), column_height)
  @test.assert_eq(frame.evicted.length(), column_height)
  for y in min_y..<=max_y {
    let generated_key = @level.chunk_key_by_chunk_xyz(1, y, 0)
    let evicted_key = @level.chunk_key_by_chunk_xyz(0, y, 0)
    assert_true(frame.generated.contains(generated_key))
    assert_true(frame.evicted.contains(evicted_key))
    assert_true(
      @level.get_chunk_data(runtime.chunk_map(), generated_key) is Some(_),
    )
    assert_true(@level.get_chunk_data(runtime.chunk_map(), evicted_key) is None)
  }
}

///|
test "infinite high-air sections are not meshed" {
  let world = @level.World::new(seed=37U, world_type=@level.WorldType::Infinite)
  let initial = world.generate_chunk(0, 0, 0).tile_map
  let runtime = ChunkRuntime::new(
    world,
    initial,
    render_distance=0,
    generation_budget=1,
    mesh_budget=1024,
  )
  let registry = BlockRegistry::create([], [])
  let frame = runtime.tick(registry, 0, 0)
  let chunk_count = runtime.chunk_max_y - runtime.chunk_min_y + 1
  let all_sections = chunk_count *
    runtime.sections_per_axis *
    runtime.sections_per_axis *
    runtime.sections_per_axis
  assert_true(frame.mesh_updates.length() < all_sections)
}

///|
test "neighbor loading invalidates only the shared section boundary" {
  let world = @level.World::new(seed=5U, world_type=@level.WorldType::Flat)
  let initial = world.generate_chunk(0, 0, 0).tile_map
  let runtime = ChunkRuntime::new(world, initial, render_distance=0)
  for key in runtime.dirty_sections.keys().to_array() {
    runtime.dirty_sections.remove(key)
  }
  runtime.loaded_columns["1,0"] = true
  let chunk_key = @level.chunk_key_by_chunk_xyz(1, 0, 0)
  for sx in 0..<runtime.sections_per_axis {
    for sy in 0..<runtime.sections_per_axis {
      for sz in 0..<runtime.sections_per_axis {
        let section = ChunkSection::{ chunk_key, x: sx, y: sy, z: sz }
        runtime.rendered_sections[section_key(chunk_key, sx, sy, sz)] = section
      }
    }
  }
  runtime.mark_loaded_neighbor_boundaries_dirty(0, 0)
  let dirty = runtime.dirty_sections
    .values()
    .to_array()
    .filter(section => section.chunk_key == chunk_key)
  @test.assert_eq(
    dirty.length(),
    runtime.sections_per_axis * runtime.sections_per_axis,
  )
  assert_true(dirty.all(section => section.x == 0))
}

///|
test "infinite streaming keeps generation and eviction off the crossing frame" {
  let world = @level.World::new(seed=43U, world_type=@level.WorldType::Infinite)
  let initial = world.generate_chunk(0, 0, 0).tile_map
  let runtime = ChunkRuntime::new(
    world,
    initial,
    render_distance=0,
    generation_work_budget=8,
    mesh_budget=1,
  )
  let registry = BlockRegistry::create([], [])
  ignore(runtime.tick(registry, 0, 0))
  let frame = runtime.tick(registry, 1, 0)
  @test.assert_eq(frame.generated.length(), 0)
  @test.assert_eq(frame.evicted.length(), 0)
  assert_true(runtime.active_infinite_column is Some(_))
  let target_key = @level.chunk_key_by_chunk_xyz(1, 0, 0)
  assert_true(@level.get_chunk_data(runtime.chunk_map(), target_key) is None)
  let retained_key = @level.chunk_key_by_chunk_xyz(0, 0, 0)
  assert_true(
    @level.get_chunk_data(runtime.chunk_map(), retained_key) is Some(_),
  )
  let mut completed = false
  for _ in 0..<80 {
    let next = runtime.tick(registry, 1, 0)
    guard next.generated.length() > 0 else { continue }
    let column_height = runtime.chunk_max_y - runtime.chunk_min_y + 1
    @test.assert_eq(next.generated.length(), column_height)
    @test.assert_eq(next.evicted.length(), column_height)
    completed = true
    break
  }
  assert_true(completed)
  assert_true(@level.get_chunk_data(runtime.chunk_map(), target_key) is Some(_))
  assert_true(@level.get_chunk_data(runtime.chunk_map(), retained_key) is None)
}

///|
test "chunk runtime normalizes render distance and refreshes scheduling" {
  let world = @level.World::new(seed=47U, world_type=@level.WorldType::Flat)
  let initial = world.generate_chunk(0, 0, 0).tile_map
  let runtime = ChunkRuntime::new(
    world,
    initial,
    render_distance=MAX_RENDER_DISTANCE + 1,
  )
  @test.assert_eq(runtime.render_distance(), MAX_RENDER_DISTANCE)
  runtime.has_desired_center = true
  runtime.set_render_distance(5)
  @test.assert_eq(runtime.render_distance(), 5)
  @test.assert_eq(runtime.has_desired_center, false)
  runtime.set_render_distance(MIN_RENDER_DISTANCE - 1)
  @test.assert_eq(runtime.render_distance(), MIN_RENDER_DISTANCE)
}
