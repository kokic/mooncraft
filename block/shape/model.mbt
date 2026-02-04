///|
pub(all) struct RenderInfo {
  faces : FaceLayerIndices
  state : UInt
}

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
}
