///|
/// Design world size (blocks) on each horizontal axis.
pub const DESIGN_WORLD_X_SIZE : Int = 128

///|
/// Design world size (blocks) on the vertical axis.
pub const DESIGN_WORLD_Y_SIZE : Int = 128

///|
/// Design world size (blocks) on each horizontal axis.
pub const DESIGN_WORLD_Z_SIZE : Int = 128

///|
pub const DESIGN_MIN_Y : Int = -DESIGN_WORLD_Y_SIZE / 2

///|
pub const DESIGN_MAX_Y : Int = -DESIGN_MIN_Y - 1

///|
const DESIGN_CHUNK_X_HALF : Int = DESIGN_WORLD_X_SIZE / (2 * CHUNK_X_SIZE)

///|
const DESIGN_CHUNK_Y_HALF : Int = DESIGN_WORLD_Y_SIZE / (2 * CHUNK_Y_SIZE)

///|
const DESIGN_CHUNK_Z_HALF : Int = DESIGN_WORLD_Z_SIZE / (2 * CHUNK_Z_SIZE)

///|
fn is_chunk_in_design_world(
  chunk_x : Int,
  chunk_y : Int,
  chunk_z : Int,
) -> Bool {
  chunk_x >= -DESIGN_CHUNK_X_HALF &&
  chunk_x < DESIGN_CHUNK_X_HALF &&
  chunk_y >= -DESIGN_CHUNK_Y_HALF &&
  chunk_y < DESIGN_CHUNK_Y_HALF &&
  chunk_z >= -DESIGN_CHUNK_Z_HALF &&
  chunk_z < DESIGN_CHUNK_Z_HALF
}

///|
/// Design world generation: an empty 128x128x128 volume with a grass floor.
fn fill_design(_world : World, chunk : Chunk) -> Chunk {
  let air = @schema.AIR_ID
  let grass = @block.lookup_by_name("grass").unwrap().internal_id()
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      for ry in 0..<CHUNK_Y_SIZE {
        let (_, wy, _) = chunk.block_rxyz_to_block_xyz(rx, ry, rz)
        let tile = if wy == DESIGN_MIN_Y { grass } else { air }
        chunk.update_tile_map(rx, ry, rz, tile)
      }
    }
  }
  chunk
}

///|
/// World Y of the grass floor of the design world.
pub fn design_surface_height() -> Int {
  DESIGN_MIN_Y
}
