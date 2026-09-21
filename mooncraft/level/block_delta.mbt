///|
/// A persistent voxel override applied after procedural world generation.
pub struct BlockDelta {
  x : Int
  y : Int
  z : Int
  id : String
} derive(Debug, ToJson, FromJson)

///|
pub extend BlockDelta with Debug::{to_repr}

///|
pub extend BlockDelta with ToJson::{to_json}

///|
pub extend BlockDelta with FromJson::{from_json}

///|
pub fn BlockDelta::new(x : Int, y : Int, z : Int, id : String) -> BlockDelta {
  { x, y, z, id, }
}
