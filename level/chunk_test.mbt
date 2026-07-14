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
