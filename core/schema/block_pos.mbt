///|
pub struct BlockPos {
  x : Int
  y : Int
  z : Int
} derive(Debug)

///|
pub fn BlockPos::BlockPos(x : Int, y : Int, z : Int) -> BlockPos {
  BlockPos::{ x, y, z }
}
