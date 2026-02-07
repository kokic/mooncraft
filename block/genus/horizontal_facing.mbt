///|
pub type HorizontalFacing

///|
/// Horizontal facing states:
/// 0 => +X, 1 => -X, 2 => +Z, 3 => -Z
pub fn HorizontalFacing::unique_name(base : String, state : UInt) -> String {
  match state {
    1 => "\{base}:x_neg"
    2 => "\{base}:z_pos"
    3 => "\{base}:z_neg"
    _ => base
  }
}

///|
/// Infer horizontal facing from player X/Z relative to placed block center.
pub fn HorizontalFacing::state_from_player(
  player_pos : Array[Double],
  place_wx : Int,
  place_wz : Int,
) -> UInt {
  if player_pos.length() < 3 {
    return 0
  }
  let bx = place_wx.to_double() + 0.5
  let bz = place_wz.to_double() + 0.5
  let dx = player_pos[0] - bx
  let dz = player_pos[2] - bz
  if dx.abs() >= dz.abs() {
    if dx >= 0.0 {
      0
    } else {
      1
    }
  } else if dz >= 0.0 {
    2
  } else {
    3
  }
}

///|
/// Map a rendered world face to source face under horizontal facing rotation.
pub fn HorizontalFacing::source_face_for_world_face(
  world_face : @shape.FaceName,
  state : UInt,
) -> @shape.FaceName {
  match state.reinterpret_as_int() {
    0 => world_face
    1 =>
      match world_face {
        @shape.FaceName::PosX => @shape.FaceName::NegX
        @shape.FaceName::NegX => @shape.FaceName::PosX
        @shape.FaceName::PosZ => @shape.FaceName::NegZ
        @shape.FaceName::NegZ => @shape.FaceName::PosZ
        _ => world_face
      }
    2 =>
      match world_face {
        @shape.FaceName::PosX => @shape.FaceName::NegZ
        @shape.FaceName::NegX => @shape.FaceName::PosZ
        @shape.FaceName::PosZ => @shape.FaceName::PosX
        @shape.FaceName::NegZ => @shape.FaceName::NegX
        _ => world_face
      }
    3 =>
      match world_face {
        @shape.FaceName::PosX => @shape.FaceName::PosZ
        @shape.FaceName::NegX => @shape.FaceName::NegZ
        @shape.FaceName::PosZ => @shape.FaceName::NegX
        @shape.FaceName::NegZ => @shape.FaceName::PosX
        _ => world_face
      }
    _ => world_face
  }
}

///|
pub fn HorizontalFacing::face_layer(
  faces : @shape.FaceLayerIndices,
  state : UInt,
  world_face : @shape.FaceName,
) -> Int {
  let source_face = HorizontalFacing::source_face_for_world_face(world_face, state)
  match source_face {
    @shape.FaceName::PosX => faces.pos_x
    @shape.FaceName::NegX => faces.neg_x
    @shape.FaceName::PosY => faces.pos_y
    @shape.FaceName::NegY => faces.neg_y
    @shape.FaceName::PosZ => faces.pos_z
    @shape.FaceName::NegZ => faces.neg_z
  }
}

///|
pub let horizontal_facing_model : @shape.Model = @shape.Model::{
  face_layer: fn(info : @shape.FaceSource, world_face : @shape.FaceName) {
    HorizontalFacing::face_layer(info.faces, info.state, world_face)
  },
  face_box: default_model.face_box,
  uv_rect: default_model.uv_rect,
  rotate_uv: default_model.rotate_uv,
  double_sided: default_model.double_sided,
  face_visible: default_model.face_visible,
  emit_mesh: default_model.emit_mesh,
  emit_colors: default_model.emit_colors,
}
