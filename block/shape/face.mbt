///|
/// Face identifier aligned with axis-aligned cube normals.
pub enum FaceName {
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
    normal: (1, 0, 0),
    corners: [(1, 0, 0), (1, 0, 1), (1, 1, 1), (1, 1, 0)],
  },
  FaceGeom::{
    name: FaceName::NegX,
    normal: (-1, 0, 0),
    corners: [(0, 0, 1), (0, 0, 0), (0, 1, 0), (0, 1, 1)],
  },
  FaceGeom::{
    name: FaceName::PosY,
    normal: (0, 1, 0),
    corners: [(0, 1, 1), (0, 1, 0), (1, 1, 0), (1, 1, 1)],
  },
  FaceGeom::{
    name: FaceName::NegY,
    normal: (0, -1, 0),
    corners: [(0, 0, 0), (0, 0, 1), (1, 0, 1), (1, 0, 0)],
  },
  FaceGeom::{
    name: FaceName::PosZ,
    normal: (0, 0, 1),
    corners: [(1, 0, 1), (0, 0, 1), (0, 1, 1), (1, 1, 1)],
  },
  FaceGeom::{
    name: FaceName::NegZ,
    normal: (0, 0, -1),
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
