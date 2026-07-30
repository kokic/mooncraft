///|
/// A persistent voxel override applied after procedural world generation.
pub struct BlockDelta {
  x : Int
  y : Int
  z : Int
  id : String
} derive(Debug, ToJson, FromJson)

///|
pub fn BlockDelta::new(x : Int, y : Int, z : Int, id : String) -> BlockDelta {
  { x, y, z, id }
}
