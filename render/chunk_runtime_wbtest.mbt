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
    let section = frame.mesh_updates.any(command => command.chunk_key == "0,0,0")
    if section {
      rebuild_seen = true
      break
    }
  }
  assert_true(rebuild_seen)
  assert_eq(runtime.block_deltas().length(), 1)
}
