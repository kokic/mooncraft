///|
test "set_block ignores coordinates outside the chunk" {
  let chunk = Chunk::new(1, -1, 2)
  let base_x = chunk.x * CHUNK_X_SIZE
  let base_y = chunk.y * CHUNK_Y_SIZE
  let base_z = chunk.z * CHUNK_Z_SIZE
  let long_id : UInt = 7

  chunk.set_block(base_x - 1, base_y, base_z, long_id)
  chunk.set_block(base_x + CHUNK_X_SIZE, base_y, base_z, long_id)
  chunk.set_block(base_x, base_y - 1, base_z, long_id)
  chunk.set_block(base_x, base_y + CHUNK_Y_SIZE, base_z, long_id)
  chunk.set_block(base_x, base_y, base_z - 1, long_id)
  chunk.set_block(base_x, base_y, base_z + CHUNK_Z_SIZE, long_id)
  inspect(chunk.get_tile(0, 0, 0), content="0")

  chunk.set_block(base_x, base_y, base_z, long_id)
  inspect(chunk.get_tile(0, 0, 0), content="7")
}

///|
test "chunk column keys round-trip negative coordinates" {
  let key = chunk_column_key_by_chunk_xz(-3, 5)
  @test.assert_eq(key, "-3,5")
  @test.assert_eq(chunk_xz_by_chunk_column_key(key), (-3, 5))
}

///|
test "world generates complete chunk columns" {
  let world = World::new(seed=3U, world_type=WorldType::Flat)
  let chunks = world.generate_chunk_column(-2, 4)
  let min_y = @util.floor_div(world.min_y(), CHUNK_Y_SIZE)
  let max_y = @util.floor_div(world.max_y(), CHUNK_Y_SIZE)
  @test.assert_eq(chunks.length(), max_y - min_y + 1)
  for i, chunk in chunks {
    @test.assert_eq(chunk.chunk_key(), chunk_key_by_chunk_xyz(-2, min_y + i, 4))
  }
}
