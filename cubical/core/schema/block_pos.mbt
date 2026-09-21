///|
pub struct BlockPos {
  x : Int
  y : Int
  z : Int
} derive(Debug)

///|
pub extend BlockPos with Debug::{to_repr}

///|
pub fn BlockPos::BlockPos(x : Int, y : Int, z : Int) -> BlockPos {
  BlockPos::{ x, y, z, }
}
