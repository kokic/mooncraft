
///|
pub const CHUNK_X_SIZE : Int = @util.CHUNK_X_SIZE

///|
pub const CHUNK_Y_SIZE : Int = @util.CHUNK_Y_SIZE

///|
pub const CHUNK_Z_SIZE : Int = @util.CHUNK_Z_SIZE

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
  @util.chunk_key_by_chunk_xyz(self.x, self.y, self.z)
}

///|
pub fn Chunk::get_tile(self : Chunk, block_rx : Int, block_ry : Int, block_rz : Int) -> UInt {
  let idx = @util.get_linear_block_index(block_rx, block_ry, block_rz)
  self.tile_map[idx]
}

///|
pub fn Chunk::set_tile(self : Chunk, block_rx : Int, block_ry : Int, block_rz : Int, long_id : UInt) -> Unit {
  let idx = @util.get_linear_block_index(block_rx, block_ry, block_rz)
  self.tile_map[idx] = long_id
}

///|
pub fn Chunk::in_other_chunk(block_rx : Int, block_ry : Int, block_rz : Int) -> Bool {
  block_rx < 0 || block_rx >= CHUNK_X_SIZE ||
  block_ry < 0 || block_ry >= CHUNK_Y_SIZE ||
  block_rz < 0 || block_rz >= CHUNK_Z_SIZE
}

///|
pub fn Chunk::block_rxyz_to_block_xyz(self : Chunk, block_rx : Int, block_ry : Int, block_rz : Int) -> (Int, Int, Int) {
  (
    block_rx + self.x * CHUNK_X_SIZE,
    block_ry + self.y * CHUNK_Y_SIZE,
    block_rz + self.z * CHUNK_Z_SIZE,
  )
}

