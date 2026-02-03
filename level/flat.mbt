///|
/// Flat world layers listed from top to bottom (y = highest .. y = 0).
let default_flat_layer_blocks : Array[String] = [
  "grass", "dirt", "dirt", "bedrock",
]

///|
/// Flat world generation with configurable layers.
fn fill_flat(
  chunk : Chunk,
  flat_layer_names? : Array[String] = default_flat_layer_blocks,
) -> Chunk {
  let air = @block.AIR_LONG_ID
  let layer_ids = flat_layer_long_ids(flat_layer_names)
  let layer_count = layer_ids.length()
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      for ry in 0..<CHUNK_Y_SIZE {
        let (_, wy, _) = chunk.block_rxyz_to_block_xyz(rx, ry, rz)
        if wy < 0 {
          chunk.set_tile(rx, ry, rz, air)
        } else if wy < layer_count {
          let idx = layer_count - 1 - wy
          chunk.set_tile(rx, ry, rz, layer_ids[idx])
        } else {
          chunk.set_tile(rx, ry, rz, air)
        }
      }
    }
  }
  chunk
}

///|
/// Resolve flat-layer names to long IDs (unknown names become air).
fn flat_layer_long_ids(flat_layer_blocks : Array[String]) -> Array[UInt] {
  let ids : Array[UInt] = []
  for name in flat_layer_blocks {
    match @block.lookup_by_name(name) {
      Some(block) => ids.push(block.long_id())
      None => ids.push(@block.AIR_LONG_ID)
    }
  }
  ids
}
