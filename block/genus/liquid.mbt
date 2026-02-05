///|
pub type Liquid

///|
/// 15.0F / 16.0F
pub const LIQUID_MAX_Y : Float = 0.9375F

///|
/// Default water tint (rgb) and alpha.
pub let water_tint : (Float, Float, Float, Float) = (
  0.247F,
  0.463F,
  0.894F,
  1.0F,
)

///|
/// Default lava tint (rgb) and alpha.
pub let lava_tint : (Float, Float, Float, Float) = (
  1.0F,
  0.42F,
  0.08F,
  0.85F,
)

///|
pub struct LiquidModelData {
  max_y : Float
  side_v0 : Float
}

///|
pub let liquid_data : LiquidModelData = LiquidModelData::{
  max_y: LIQUID_MAX_Y,
  side_v0: 1.0F - LIQUID_MAX_Y,
}

///|
pub fn Liquid::face_box(
  _face : @shape.FaceName,
) -> ((Float, Float, Float), (Float, Float, Float))? {
  let data = liquid_data
  Some(((0.0F, 0.0F, 0.0F), (1.0F, data.max_y, 1.0F)))
}

///|
pub fn Liquid::uv_rect(
  face : @shape.FaceName,
) -> (Float, Float, Float, Float) {
  let v0 = liquid_data.side_v0
  match face {
    @shape.FaceName::PosX
    | @shape.FaceName::NegX
    | @shape.FaceName::PosZ
    | @shape.FaceName::NegZ => (0.0F, v0, 1.0F, 1.0F)
    _ => (0.0F, 0.0F, 1.0F, 1.0F)
  }
}

///|
pub let liquid_model : @shape.Model = @shape.Model::{
  face_layer: face_layer_default,
  face_box: fn(_info : @shape.FaceSource, face : @shape.FaceName) {
    Liquid::face_box(face)
  },
  uv_rect: fn(_info : @shape.FaceSource, face : @shape.FaceName) {
    Liquid::uv_rect(face)
  },
  rotate_uv: rotate_uv_none,
  double_sided: double_sided_false,
  emit_mesh: emit_mesh_none,
  emit_colors: emit_colors_none,
}
