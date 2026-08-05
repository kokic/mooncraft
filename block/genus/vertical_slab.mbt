///|
pub type VerticalSlab

///|
/// The half dimension shared with the horizontal slab (8.0F / 16.0F).
pub const VERTICAL_SLAB_MAX : Float = SLAB_MAX_Y

///|
/// Vertical slab states select which half of the cell the slab occupies:
/// 0 => -X half, 1 => +X half, 2 => -Z half, 3 => +Z half.
pub fn VerticalSlab::unique_name(base : String, state : UInt) -> String {
  match state {
    1 => "\{base}:x_pos"
    2 => "\{base}:z_neg"
    3 => "\{base}:z_pos"
    _ => "\{base}"
  }
}

///|
pub fn VerticalSlab::box(state : UInt) -> @shape.Box {
  match state.reinterpret_as_int() {
    1 =>
      @shape.Box::{
        min: [VERTICAL_SLAB_MAX, 0.0F, 0.0F],
        max: [1.0F, 1.0F, 1.0F],
      }
    2 =>
      @shape.Box::{
        min: [0.0F, 0.0F, 0.0F],
        max: [1.0F, 1.0F, VERTICAL_SLAB_MAX],
      }
    3 =>
      @shape.Box::{
        min: [0.0F, 0.0F, VERTICAL_SLAB_MAX],
        max: [1.0F, 1.0F, 1.0F],
      }
    _ =>
      @shape.Box::{
        min: [0.0F, 0.0F, 0.0F],
        max: [VERTICAL_SLAB_MAX, 1.0F, 1.0F],
      }
  }
}

///|
pub fn VerticalSlab::face_box(
  state : UInt,
) -> ((Float, Float, Float), (Float, Float, Float))? {
  match state.reinterpret_as_int() {
    1 => Some(((VERTICAL_SLAB_MAX, 0.0F, 0.0F), (1.0F, 1.0F, 1.0F)))
    2 => Some(((0.0F, 0.0F, 0.0F), (1.0F, 1.0F, VERTICAL_SLAB_MAX)))
    3 => Some(((0.0F, 0.0F, VERTICAL_SLAB_MAX), (1.0F, 1.0F, 1.0F)))
    _ => Some(((0.0F, 0.0F, 0.0F), (VERTICAL_SLAB_MAX, 1.0F, 1.0F)))
  }
}

///|
fn vertical_slab_face_box(
  info : @shape.FaceSource,
  _face : @shape.FaceName,
) -> ((Float, Float, Float), (Float, Float, Float))? {
  VerticalSlab::face_box(info.state)
}

///|
/// The slab sits against the face that was hit: a +X hit occupies the -X half
/// and so on. Top/bottom placements pick the half from the click quadrant.
pub fn VerticalSlab::state_from_placement(
  block : Array[Int],
  prev : Array[Int],
  click : (Float, Float, Float),
) -> UInt {
  match @shape.FaceName::from_adjacent_blocks(block, prev) {
    Some(@shape.FaceName::PosX) => 0
    Some(@shape.FaceName::NegX) => 1
    Some(@shape.FaceName::PosZ) => 2
    Some(@shape.FaceName::NegZ) => 3
    _ => {
      let (cx, _, cz) = click
      if cx < 0.5F && cz < 0.5F {
        0
      } else if cx >= 0.5F && cz < 0.5F {
        1
      } else if cx < 0.5F && cz >= 0.5F {
        2
      } else {
        3
      }
    }
  }
}

///|
/// Narrow faces show the texture strip that occupies the slab's half: faces
/// cut short in X show the -X or +X half, faces cut short in Z the -Z or +Z
/// half. Full-height faces perpendicular to the thickness axis stay full.
pub fn VerticalSlab::uv_rect(
  state : UInt,
  face : @shape.FaceName,
) -> (Float, Float, Float, Float) {
  match state.reinterpret_as_int() {
    0 | 1 => {
      let start = if state.reinterpret_as_int() == 1 {
        VERTICAL_SLAB_MAX
      } else {
        0.0F
      }
      match face {
        @shape.FaceName::PosY | @shape.FaceName::NegY =>
          (0.0F, start, 1.0F, start + VERTICAL_SLAB_MAX)
        @shape.FaceName::PosZ =>
          (VERTICAL_SLAB_MAX - start, 0.0F, 1.0F - start, 1.0F)
        @shape.FaceName::NegZ => (start, 0.0F, start + VERTICAL_SLAB_MAX, 1.0F)
        _ => (0.0F, 0.0F, 1.0F, 1.0F)
      }
    }
    _ => {
      let start = if state.reinterpret_as_int() == 3 {
        VERTICAL_SLAB_MAX
      } else {
        0.0F
      }
      match face {
        @shape.FaceName::PosY | @shape.FaceName::NegX =>
          (VERTICAL_SLAB_MAX - start, 0.0F, 1.0F - start, 1.0F)
        @shape.FaceName::NegY | @shape.FaceName::PosX =>
          (start, 0.0F, start + VERTICAL_SLAB_MAX, 1.0F)
        _ => (0.0F, 0.0F, 1.0F, 1.0F)
      }
    }
  }
}

///|
fn vertical_slab_uv_rect(
  info : @shape.FaceSource,
  face : @shape.FaceName,
) -> (Float, Float, Float, Float) {
  VerticalSlab::uv_rect(info.state, face)
}

///|
pub let vertical_slab_model : @shape.Model = @shape.Model::{
  face_layer: face_layer_default,
  face_box: vertical_slab_face_box,
  uv_rect: vertical_slab_uv_rect,
  rotate_uv: rotate_uv_none,
  double_sided: double_sided_false,
  face_visible: fn(
    info : @shape.FaceSource,
    face : @shape.FaceGeom,
    occlusion : @shape.FaceOcclusion,
  ) {
    face_visible_default(vertical_slab_face_box, info, face, occlusion)
  },
  emit_mesh: emit_mesh_none,
  emit_colors: emit_colors_none,
}
