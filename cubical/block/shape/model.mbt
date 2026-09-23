///|
pub(all) struct FaceSource {
  faces : FaceLayerIndices
  state : UInt
}

///|
pub(all) struct FaceOcclusion {
  neighbor_occludes : Bool
  same_block_cull : Bool
}

///|
pub type Vertex = (Float, Float, Float)

///|
pub type FaceNormal = (Int, Int, Int)

///|
pub type FaceLayer = Float

///|
pub type UvRect = (Float, Float, Float, Float)

///|
pub type FlipV = Bool

///|
pub type ColorScale = Float

///|
pub type FaceEmitter = (
  Vertex,
  Vertex,
  Vertex,
  Vertex,
  FaceNormal,
  FaceLayer,
  UvRect,
  FlipV,
  ColorScale,
) -> Unit

///|
pub type ColorEmitter = (Int, Float) -> Unit

///|
pub(all) struct Model {
  face_layer : (FaceSource, FaceName) -> Int
  face_box : (FaceSource, FaceName) -> (
    (Float, Float, Float),
    (Float, Float, Float),
  )?
  uv_rect : (FaceSource, FaceName) -> (Float, Float, Float, Float)
  rotate_uv : (FaceSource, FaceGeom) -> Bool
  double_sided : (FaceSource) -> Bool
  face_visible : (FaceSource, FaceGeom, FaceOcclusion) -> Bool
  emit_mesh : (FaceSource, Float, Float, Float, FaceEmitter, FaceEmitter) -> Bool
  emit_colors : (FaceSource, ColorEmitter) -> Bool
}
