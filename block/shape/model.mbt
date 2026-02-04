///|
pub(all) struct RenderInfo {
  faces : FaceLayerIndices
  state : UInt
}

///|
pub type FaceEmitter = (
  (Float, Float, Float),
  (Float, Float, Float),
  (Float, Float, Float),
  (Float, Float, Float),
  (Int, Int, Int),
  Float,
  (Float, Float, Float, Float),
  Bool,
  Float,
) -> Unit

///|
pub type ColorEmitter = (Int, Float) -> Unit

///|
pub(all) struct Model {
  face_layer : (RenderInfo, FaceName) -> Int
  face_box : (RenderInfo, FaceName) -> (
    (Float, Float, Float),
    (Float, Float, Float),
  )?
  uv_rect : (RenderInfo, FaceName) -> (Float, Float, Float, Float)
  rotate_uv : (RenderInfo, FaceGeom) -> Bool
  double_sided : (RenderInfo) -> Bool
  emit_mesh : (RenderInfo, Float, Float, Float, FaceEmitter, FaceEmitter) -> Bool
  emit_colors : (RenderInfo, ColorEmitter) -> Bool
}
