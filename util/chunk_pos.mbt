///|
pub struct ChunkBlockPos {
  x : Int
  y : Int
  z : Int
} derive(Show)

///|
const SHIFT_X = 4

///|
const SHIFT_Y = 4

///|
const SHIFT_Z = 4

///|
pub const CHUNK_X_SIZE : Int = 1 << SHIFT_X

///|
pub const CHUNK_Y_SIZE : Int = 1 << SHIFT_Y

///|
pub const CHUNK_Z_SIZE : Int = 1 << SHIFT_Z

///|
pub fn ChunkBlockPos::from_block_pos(block_pos : BlockPos) -> ChunkBlockPos {
  ChunkBlockPos::{
    x: block_pos.x >> SHIFT_X,
    y: block_pos.y >> SHIFT_Y,
    z: block_pos.z >> SHIFT_Z,
  }
}
