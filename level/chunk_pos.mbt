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

///|
pub fn chunk_key_by_chunk_xyz(
  chunk_x : Int,
  chunk_y : Int,
  chunk_z : Int,
) -> String {
  "\{chunk_x},\{chunk_y},\{chunk_z}"
}

///|
pub fn chunk_key_by_block_xyz(
  block_x : Int,
  block_y : Int,
  block_z : Int,
) -> String {
  "\{block_x >> SHIFT_X},\{block_y >> SHIFT_Y},\{block_z >> SHIFT_Z}"
}

///|
pub fn chunk_xyz_by_chunk_key(chunk_key : String) -> (Int, Int, Int) {
  let parts : Array[StringView] = []
  for part in chunk_key.split(",") {
    parts.push(part)
  }
  let parse_int_or_zero = fn(sv : StringView) -> Int {
    try @strconv.parse_int(sv) catch {
      _ => 0
    } noraise {
      v => v
    }
  }
  if parts.length() != 3 {
    (0, 0, 0)
  } else {
    (
      parse_int_or_zero(parts[0]),
      parse_int_or_zero(parts[1]),
      parse_int_or_zero(parts[2]),
    )
  }
}

///|
pub fn get_relative_block_xyz(
  block_x : Int,
  block_y : Int,
  block_z : Int,
) -> (Int, Int, Int) {
  let mod = fn(n : Int, m : Int) -> Int { (m + n % m) % m }
  (
    mod(block_x, CHUNK_X_SIZE),
    mod(block_y, CHUNK_Y_SIZE),
    mod(block_z, CHUNK_Z_SIZE),
  )
}

///|
/// YZX = y * Y_SIZE * Z_SIZE + z * Z_SIZE + x
pub fn get_linear_block_index(
  block_rx : Int,
  block_ry : Int,
  block_rz : Int,
) -> Int {
  (((block_ry << SHIFT_Y) + block_rz) << SHIFT_Z) | block_rx
}

///|
/// x = index % X_SIZE; z = ((index - x) / Z_SIZE) % Z_SIZE; y = (index - x - z * Z_SIZE) / (Y_SIZE * Z_SIZE)
pub fn get_block_rxyz_by_linear_index(index : Int) -> (Int, Int, Int) {
  let block_x = index & (CHUNK_X_SIZE - 1)
  let block_z = (index >> SHIFT_Z) & (CHUNK_Z_SIZE - 1)
  let block_y = (index >> SHIFT_Y >> SHIFT_Z) & (CHUNK_Y_SIZE - 1)
  (block_x, block_y, block_z)
}
