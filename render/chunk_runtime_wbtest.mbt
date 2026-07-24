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
  let initial_frame = runtime.tick(0, 0)
  assert_true(initial_frame.full_rebuilds.length() > 0)
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
  let frame = runtime.tick(0, 0)
  assert_true(frame.section_rebuilds.length() > 0)
  assert_eq(runtime.block_deltas().length(), 1)
}
