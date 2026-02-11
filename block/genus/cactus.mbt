///|
pub type Cactus

///|
/// 1.0F / 16.0F
pub const CACTUS_MIN : Float = 0.0625F

///|
/// 15.0F / 16.0F
pub const CACTUS_MAX : Float = 0.9375F

///|
pub struct CactusModelData {
  min : Float
  max : Float
  double_sided : Bool
}

///|
pub let cactus_data : CactusModelData = CactusModelData::{
  min: CACTUS_MIN,
  max: CACTUS_MAX,
  double_sided: true,
}

///|
pub fn Cactus::face_box(
  face : @shape.FaceName,
) -> ((Float, Float, Float), (Float, Float, Float))? {
  let data = cactus_data
  let u0 = data.min
  let u1 = data.max
  match face {
    @shape.FaceName::PosX => Some(((u1, 0.0F, 0.0F), (u1, 1.0F, 1.0F)))
    @shape.FaceName::NegX => Some(((u0, 0.0F, 0.0F), (u0, 1.0F, 1.0F)))
    @shape.FaceName::PosZ => Some(((0.0F, 0.0F, u1), (1.0F, 1.0F, u1)))
    @shape.FaceName::NegZ => Some(((0.0F, 0.0F, u0), (1.0F, 1.0F, u0)))
    @shape.FaceName::PosY | @shape.FaceName::NegY =>
      Some(((u0, 0.0F, u0), (u1, 1.0F, u1)))
  }
}

///|
fn cactus_face_box(
  _info : @shape.FaceSource,
  face : @shape.FaceName,
) -> ((Float, Float, Float), (Float, Float, Float))? {
  Cactus::face_box(face)
}

///|
pub fn Cactus::uv_rect(face : @shape.FaceName) -> (Float, Float, Float, Float) {
  let data = cactus_data
  let u0 = data.min
  let u1 = data.max
  match face {
    @shape.FaceName::PosY | @shape.FaceName::NegY => (u0, u0, u1, u1)
    _ => (0.0F, 0.0F, 1.0F, 1.0F)
  }
}

///|
pub fn Cactus::double_sided() -> Bool {
  cactus_data.double_sided
}

///|
pub let cactus_model : @shape.Model = @shape.Model::{
  face_layer: face_layer_default,
  face_box: cactus_face_box,
  uv_rect: fn(_info : @shape.FaceSource, face : @shape.FaceName) {
    Cactus::uv_rect(face)
  },
  rotate_uv: rotate_uv_none,
  double_sided: fn(_info : @shape.FaceSource) { Cactus::double_sided() },
  face_visible: fn(
    info : @shape.FaceSource,
    face : @shape.FaceGeom,
    occlusion : @shape.FaceOcclusion,
  ) {
    face_visible_default(cactus_face_box, info, face, occlusion)
  },
  emit_mesh: emit_mesh_none,
  emit_colors: emit_colors_none,
}
