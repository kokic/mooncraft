///|
pub type Slab

///|
/// 8.0F / 16.0F
pub const SLAB_MAX_Y : Float = 0.5F

///|
pub struct SlabModelData {
  max_y : Float
}

///|
pub let slab_data : SlabModelData = SlabModelData::{ max_y: SLAB_MAX_Y }

///|
pub fn Slab::unique_name(base : String, state : UInt) -> String {
  match state {
    1 => "\{base}:top"
    _ => "\{base}"
  }
}

///|
pub fn Slab::box(state : UInt) -> @shape.Box {
  match state.reinterpret_as_int() {
    1 => @shape.Box::{ min: [0.0F, SLAB_MAX_Y, 0.0F], max: [1.0F, 1.0F, 1.0F] }
    _ => @shape.Box::{ min: [0.0F, 0.0F, 0.0F], max: [1.0F, SLAB_MAX_Y, 1.0F] }
  }
}

///|
pub fn Slab::face_box(
  state : UInt,
) -> ((Float, Float, Float), (Float, Float, Float))? {
  match state.reinterpret_as_int() {
    1 => Some(((0.0F, SLAB_MAX_Y, 0.0F), (1.0F, 1.0F, 1.0F)))
    _ => Some(((0.0F, 0.0F, 0.0F), (1.0F, SLAB_MAX_Y, 1.0F)))
  }
}

///|
fn slab_face_box(
  info : @shape.FaceSource,
  _face : @shape.FaceName,
) -> ((Float, Float, Float), (Float, Float, Float))? {
  Slab::face_box(info.state)
}

///|
/// The half the placed slab takes is decided like vanilla: a block's top face
/// gets the bottom half, its underside gets the top half, and side faces pick
/// the half from the click height.
pub fn Slab::state_from_placement(
  block : Array[Int],
  prev : Array[Int],
  click : (Float, Float, Float),
) -> UInt {
  match @shape.FaceName::from_adjacent_blocks(block, prev) {
    Some(@shape.FaceName::PosY) => 0
    Some(@shape.FaceName::NegY) => 1
    Some(_) => if click.1 > 0.5F { 1 } else { 0 }
    None => 0
  }
}

///|
/// Side faces render only the texture strip that occupies the slab's height:
/// the bottom half for the lower slab and the top half for the upper slab.
pub fn Slab::uv_rect(
  state : UInt,
  face : @shape.FaceName,
) -> (Float, Float, Float, Float) {
  match face {
    @shape.FaceName::PosX
    | @shape.FaceName::NegX
    | @shape.FaceName::PosZ
    | @shape.FaceName::NegZ =>
      match state.reinterpret_as_int() {
        1 => (0.0F, 0.0F, 1.0F, SLAB_MAX_Y)
        _ => (0.0F, SLAB_MAX_Y, 1.0F, 1.0F)
      }
    _ => (0.0F, 0.0F, 1.0F, 1.0F)
  }
}

///|
fn slab_uv_rect(
  info : @shape.FaceSource,
  face : @shape.FaceName,
) -> (Float, Float, Float, Float) {
  Slab::uv_rect(info.state, face)
}

///|
pub let slab_model : @shape.Model = @shape.Model::{
  face_layer: face_layer_default,
  face_box: slab_face_box,
  uv_rect: slab_uv_rect,
  rotate_uv: rotate_uv_none,
  double_sided: double_sided_false,
  face_visible: fn(
    info : @shape.FaceSource,
    face : @shape.FaceGeom,
    occlusion : @shape.FaceOcclusion,
  ) {
    face_visible_default(slab_face_box, info, face, occlusion)
  },
  emit_mesh: emit_mesh_none,
  emit_colors: emit_colors_none,
}
