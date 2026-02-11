///|
pub type Log

///|
pub fn Log::unique_name(base : String, state : UInt) -> String {
  match state {
    1 => "\{base}:x"
    2 => "\{base}:z"
    _ => "\{base}"
  }
}

///|
/// Infer log placement state (axis) from the target block and previous hit.
/// 0 => Y, 1 => X, 2 => Z
pub fn Log::log_state_from_placement(
  block : Array[Int],
  prev : Array[Int],
) -> UInt {
  if block.length() < 3 || prev.length() < 3 {
    0
  } else {
    let dx = block[0] - prev[0]
    let dy = block[1] - prev[1]
    let dz = block[2] - prev[2]
    if dy != 0 {
      0
    } else if dx != 0 {
      1
    } else if dz != 0 {
      2
    } else {
      0
    }
  }
}

///|
/// 0 => Y, 1 => X, 2 => Z
pub fn Log::axis_from_state(state : UInt) -> Int {
  match state.reinterpret_as_int() {
    1 => 1
    2 => 2
    _ => 0
  }
}

///|
fn axis_from_dir(dx : Int, dy : Int, dz : Int) -> Int {
  if dx != 0 {
    1
  } else if dy != 0 {
    0
  } else if dz != 0 {
    2
  } else {
    -1
  }
}

///|
pub fn Log::rotate_uv(face : @shape.FaceGeom, state : UInt) -> Bool {
  let axis = Log::axis_from_state(state)
  let is_end_face = match axis {
    1 =>
      face.name is @shape.FaceName::PosX || face.name is @shape.FaceName::NegX
    2 =>
      face.name is @shape.FaceName::PosZ || face.name is @shape.FaceName::NegZ
    _ =>
      face.name is @shape.FaceName::PosY || face.name is @shape.FaceName::NegY
  }
  if is_end_face || face.corners.length() < 4 {
    false
  } else {
    let (ax, ay, az) = face.corners[0]
    let (bx, by, bz) = face.corners[1]
    let (dx, dy, dz) = face.corners[3]
    let u_axis = axis_from_dir(bx - ax, by - ay, bz - az)
    let v_axis = axis_from_dir(dx - ax, dy - ay, dz - az)
    if v_axis == axis {
      false
    } else {
      u_axis == axis
    }
  }
}

///|
fn face_layer_log(info : @shape.FaceSource, face : @shape.FaceName) -> Int {
  let end_layer = info.faces.pos_y
  let side_layer = info.faces.pos_x
  let axis = Log::axis_from_state(info.state)
  match axis {
    1 =>
      match face {
        @shape.FaceName::PosX | @shape.FaceName::NegX => end_layer
        _ => side_layer
      }
    2 =>
      match face {
        @shape.FaceName::PosZ | @shape.FaceName::NegZ => end_layer
        _ => side_layer
      }
    _ =>
      match face {
        @shape.FaceName::PosY | @shape.FaceName::NegY => end_layer
        _ => side_layer
      }
  }
}

///|
pub let log_model : @shape.Model = @shape.Model::{
  face_layer: face_layer_log,
  face_box: face_box_none,
  uv_rect: uv_rect_default,
  rotate_uv: fn(info : @shape.FaceSource, face : @shape.FaceGeom) {
    Log::rotate_uv(face, info.state)
  },
  double_sided: double_sided_false,
  face_visible: fn(
    info : @shape.FaceSource,
    face : @shape.FaceGeom,
    occlusion : @shape.FaceOcclusion,
  ) {
    face_visible_default(face_box_none, info, face, occlusion)
  },
  emit_mesh: emit_mesh_none,
  emit_colors: emit_colors_none,
}
