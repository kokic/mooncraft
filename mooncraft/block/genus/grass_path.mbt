///|
pub type GrassPath

///|
/// 15.0F / 16.0F
pub const GRASS_PATH_MAX_Y : Float = 0.9375F

///|
pub struct GrassPathModelData {
  max_y : Float
  side_v0 : Float
}

///|
pub let grass_path_data : GrassPathModelData = GrassPathModelData::{
  max_y: GRASS_PATH_MAX_Y,
  side_v0: 1.0F - GRASS_PATH_MAX_Y,
}

///|
pub fn GrassPath::face_box(
  _face : @shape.FaceName,
) -> ((Float, Float, Float), (Float, Float, Float))? {
  let data = grass_path_data
  Some(((0.0F, 0.0F, 0.0F), (1.0F, data.max_y, 1.0F)))
}

///|
fn grass_path_face_box(
  _info : @shape.FaceSource,
  face : @shape.FaceName,
) -> ((Float, Float, Float), (Float, Float, Float))? {
  GrassPath::face_box(face)
}

///|
pub fn GrassPath::uv_rect(
  face : @shape.FaceName,
) -> (Float, Float, Float, Float) {
  let v0 = grass_path_data.side_v0
  match face {
    @shape.FaceName::PosX
    | @shape.FaceName::NegX
    | @shape.FaceName::PosZ
    | @shape.FaceName::NegZ => (0.0F, v0, 1.0F, 1.0F)
    _ => (0.0F, 0.0F, 1.0F, 1.0F)
  }
}

///|
pub let grass_path_model : @shape.Model = @shape.Model::{
  face_layer: face_layer_default,
  face_box: grass_path_face_box,
  uv_rect: fn(_info : @shape.FaceSource, face : @shape.FaceName) {
    GrassPath::uv_rect(face)
  },
  rotate_uv: rotate_uv_none,
  double_sided: double_sided_false,
  face_visible: fn(
    info : @shape.FaceSource,
    face : @shape.FaceGeom,
    occlusion : @shape.FaceOcclusion,
  ) {
    face_visible_default(grass_path_face_box, info, face, occlusion)
  },
  emit_mesh: emit_mesh_none,
  emit_colors: emit_colors_none,
}
