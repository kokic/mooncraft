///|
pub struct Chunk {
  x : Int
  y : Int
  z : Int
  tile_map : Array[UInt]
}

///|
pub fn Chunk::new(x : Int, y : Int, z : Int) -> Chunk {
  let size = CHUNK_X_SIZE * CHUNK_Y_SIZE * CHUNK_Z_SIZE
  Chunk::{ x, y, z, tile_map: Array::make(size, 0) }
}

///|
pub fn Chunk::chunk_key(self : Chunk) -> String {
  chunk_key_by_chunk_xyz(self.x, self.y, self.z)
}

///|
pub fn Chunk::get_tile(
  self : Chunk,
  block_rx : Int,
  block_ry : Int,
  block_rz : Int,
) -> UInt {
  let idx = get_linear_block_index(block_rx, block_ry, block_rz)
  self.tile_map[idx]
}

///|
pub fn Chunk::update_tile_map(
  self : Chunk,
  block_rx : Int,
  block_ry : Int,
  block_rz : Int,
  long_id : UInt,
) -> Unit {
  let idx = get_linear_block_index(block_rx, block_ry, block_rz)
  self.tile_map[idx] = long_id
}

///|
pub fn Chunk::in_other_chunk(
  block_rx : Int,
  block_ry : Int,
  block_rz : Int,
) -> Bool {
  block_rx < 0 ||
  block_rx >= CHUNK_X_SIZE ||
  block_ry < 0 ||
  block_ry >= CHUNK_Y_SIZE ||
  block_rz < 0 ||
  block_rz >= CHUNK_Z_SIZE
}

///|
pub fn Chunk::block_rxyz_to_block_xyz(
  self : Chunk,
  block_rx : Int,
  block_ry : Int,
  block_rz : Int,
) -> (Int, Int, Int) {
  (
    block_rx + self.x * CHUNK_X_SIZE,
    block_ry + self.y * CHUNK_Y_SIZE,
    block_rz + self.z * CHUNK_Z_SIZE,
  )
}

///|
pub fn Chunk::set_block(
  chunk : Chunk,
  wx : Int,
  wy : Int,
  wz : Int,
  long_id : UInt,
) -> Unit {
  let base_x = chunk.x * CHUNK_X_SIZE
  let base_y = chunk.y * CHUNK_Y_SIZE
  let base_z = chunk.z * CHUNK_Z_SIZE
  if wx < base_x || wx >= base_x + CHUNK_X_SIZE {
    return
  }
  if wy < base_y || wy >= base_y + CHUNK_Y_SIZE {
    return
  }
  if wz < base_z || wz >= base_z + CHUNK_Z_SIZE {
    return
  }
  let rx = wx - base_x
  let ry = wy - base_y
  let rz = wz - base_z
  chunk.update_tile_map(rx, ry, rz, long_id)
}
