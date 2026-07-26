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
  ignore(
    @level.set_block_id(
      runtime.chunk_map(),
      @level.CHUNK_X_SIZE,
      1,
      1,
      1,
      stone,
    ),
  )
  runtime.mark_block_changed(1, 1, 1)
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
