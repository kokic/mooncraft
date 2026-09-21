///|
/// Face identifier aligned with axis-aligned cube normals.
pub(all) enum FaceName {
  /// X+ face (normal = (1, 0, 0))
  PosX
  /// X- face (normal = (-1, 0, 0))
  NegX
  /// Y+ face (normal = (0, 1, 0))
  PosY
  /// Y- face (normal = (0, -1, 0))
  NegY
  /// Z+ face (normal = (0, 0, 1))
  PosZ
  /// Z- face (normal = (0, 0, -1))
  NegZ
}

///|
pub fn FaceName::index(face : FaceName) -> Int {
  match face {
    FaceName::PosX => 0
    FaceName::NegX => 1
    FaceName::PosY => 2
    FaceName::NegY => 3
    FaceName::PosZ => 4
    FaceName::NegZ => 5
  }
}

///|
pub fn FaceName::normal(face : FaceName) -> (Int, Int, Int) {
  match face {
    FaceName::PosX => (1, 0, 0)
    FaceName::NegX => (-1, 0, 0)
    FaceName::PosY => (0, 1, 0)
    FaceName::NegY => (0, -1, 0)
    FaceName::PosZ => (0, 0, 1)
    FaceName::NegZ => (0, 0, -1)
  }
}

///|
pub fn FaceName::axis_index(face : FaceName) -> Int {
  match face {
    FaceName::PosX | FaceName::NegX => 1
    FaceName::PosY | FaceName::NegY => 0
    FaceName::PosZ | FaceName::NegZ => 2
  }
}

///|
pub fn FaceName::from_hit_delta(dx : Int, dy : Int, dz : Int) -> FaceName? {
  if dx == -1 {
    Some(FaceName::PosX)
  } else if dx == 1 {
    Some(FaceName::NegX)
  } else if dy == -1 {
    Some(FaceName::PosY)
  } else if dy == 1 {
    Some(FaceName::NegY)
  } else if dz == -1 {
    Some(FaceName::PosZ)
  } else if dz == 1 {
    Some(FaceName::NegZ)
  } else {
    None
  }
}

///|
pub fn FaceName::from_adjacent_blocks(
  block : Array[Int],
  prev : Array[Int],
) -> FaceName? {
  guard block.length() >= 3 && prev.length() >= 3 else { None }
  FaceName::from_hit_delta(
    block[0] - prev[0],
    block[1] - prev[1],
    block[2] - prev[2],
  )
}

///|
/// Geometric definition for a cube face (normal + corners).
pub struct FaceGeom {
  name : FaceName
  normal : (Int, Int, Int)
  corners : Array[(Int, Int, Int)]
}

///|
pub let faces : Array[FaceGeom] = [
  FaceGeom::{
    name: FaceName::PosX,
    normal: FaceName::normal(FaceName::PosX),
    corners: [(1, 0, 0), (1, 0, 1), (1, 1, 1), (1, 1, 0)],
  },
  FaceGeom::{
    name: FaceName::NegX,
    normal: FaceName::normal(FaceName::NegX),
    corners: [(0, 0, 1), (0, 0, 0), (0, 1, 0), (0, 1, 1)],
  },
  FaceGeom::{
    name: FaceName::PosY,
    normal: FaceName::normal(FaceName::PosY),
    corners: [(0, 1, 1), (0, 1, 0), (1, 1, 0), (1, 1, 1)],
  },
  FaceGeom::{
    name: FaceName::NegY,
    normal: FaceName::normal(FaceName::NegY),
    corners: [(0, 0, 0), (0, 0, 1), (1, 0, 1), (1, 0, 0)],
  },
  FaceGeom::{
    name: FaceName::PosZ,
    normal: FaceName::normal(FaceName::PosZ),
    corners: [(1, 0, 1), (0, 0, 1), (0, 1, 1), (1, 1, 1)],
  },
  FaceGeom::{
    name: FaceName::NegZ,
    normal: FaceName::normal(FaceName::NegZ),
    corners: [(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0)],
  },
]

///|
/// Per-face texture layer indices.
pub(all) struct FaceLayerIndices {
  pos_x : Int
  neg_x : Int
  pos_y : Int
  neg_y : Int
  pos_z : Int
  neg_z : Int
}
