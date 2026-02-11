///|
pub type SixFacing

///|
/// Notes from the piston UV bugfix:
///
/// 1) Root cause:
///    We mixed "orientation mapping" and "UV roll" into one transform.
///    This caused correct states (X/Z facing) to regress when fixing Y facing.
///
/// 2) Stable approach:
///    - First decide source/world face mapping by rigid orientation only.
///    - Then solve UV by comparing face-local U/V axes after:
///      source roll + world correction.
///
/// 3) Correctness criterion:
///    For each `(state, world_face)`, final U/V directions in world space must
///    match expected source U/V directions in world space.
///    We then choose `(rotate_uv, flip_u, flip_v)` that yields this equality.
///
/// 4) Performance:
///    `state x face` has only 36 combinations. We precompute:
///    - source face lookup
///    - UV transform flags
///    so runtime mesh emission only does table lookups.
const SIX_FACING_FACE_COUNT : Int = 6

///|
let all_faces : Array[@shape.FaceName] = [
  @shape.FaceName::PosX,
  @shape.FaceName::NegX,
  @shape.FaceName::PosY,
  @shape.FaceName::NegY,
  @shape.FaceName::PosZ,
  @shape.FaceName::NegZ,
]

///|
let all_states : Array[UInt] = [0, 1, 2, 3, 4, 5]

///|
/// Six-way facing states:
/// 0 => +X, 1 => -X, 2 => +Y, 3 => -Y, 4 => +Z, 5 => -Z
pub fn SixFacing::unique_name(base : String, state : UInt) -> String {
  match state {
    1 => "\{base}:x_neg"
    2 => "\{base}:y_pos"
    3 => "\{base}:y_neg"
    4 => "\{base}:z_pos"
    5 => "\{base}:z_neg"
    _ => base
  }
}

///|
pub fn SixFacing::state_from_face(face : @shape.FaceName) -> UInt {
  match face {
    @shape.FaceName::PosX => 0
    @shape.FaceName::NegX => 1
    @shape.FaceName::PosY => 2
    @shape.FaceName::NegY => 3
    @shape.FaceName::PosZ => 4
    @shape.FaceName::NegZ => 5
  }
}

///|
pub fn SixFacing::face_from_state(state : UInt) -> @shape.FaceName {
  match state.reinterpret_as_int() {
    1 => @shape.FaceName::NegX
    2 => @shape.FaceName::PosY
    3 => @shape.FaceName::NegY
    4 => @shape.FaceName::PosZ
    5 => @shape.FaceName::NegZ
    _ => @shape.FaceName::PosX
  }
}

///|
/// Infer facing from hit data (`block` is target, `prev` is placement position).
pub fn SixFacing::state_from_hit(block : Array[Int], prev : Array[Int]) -> UInt {
  if block.length() < 3 || prev.length() < 3 {
    0
  } else {
    let dx = block[0] - prev[0]
    let dy = block[1] - prev[1]
    let dz = block[2] - prev[2]
    if dx == -1 {
      0
    } else if dx == 1 {
      1
    } else if dy == -1 {
      2
    } else if dy == 1 {
      3
    } else if dz == -1 {
      4
    } else if dz == 1 {
      5
    } else {
      0
    }
  }
}

///|
/// Map a rendered world face to source face under six-way orientation.
/// Source default orientation uses +X as "front".
fn calc_source_face_for_world_face(
  world_face : @shape.FaceName,
  state : UInt,
) -> @shape.FaceName {
  let world_dir = face_dir(world_face)
  for source_face in all_faces {
    if rotate_dir_by_state(state, face_dir(source_face)) == world_dir {
      return source_face
    }
  }
  world_face
}

///|
fn face_index(face : @shape.FaceName) -> Int {
  match face {
    @shape.FaceName::PosX => 0
    @shape.FaceName::NegX => 1
    @shape.FaceName::PosY => 2
    @shape.FaceName::NegY => 3
    @shape.FaceName::PosZ => 4
    @shape.FaceName::NegZ => 5
  }
}

///|
fn state_index(state : UInt) -> Int {
  match state.reinterpret_as_int() {
    1 => 1
    2 => 2
    3 => 3
    4 => 4
    5 => 5
    _ => 0
  }
}

///|
fn table_index(state : UInt, face : @shape.FaceName) -> Int {
  state_index(state) * SIX_FACING_FACE_COUNT + face_index(face)
}

///|
let source_face_table : Array[@shape.FaceName] = {
  let table = Array::make(
    SIX_FACING_FACE_COUNT * SIX_FACING_FACE_COUNT,
    @shape.FaceName::PosX,
  )
  for state in all_states {
    for face in all_faces {
      table[table_index(state, face)] = calc_source_face_for_world_face(
        face, state,
      )
    }
  }
  table
}

///|
pub fn SixFacing::source_face_for_world_face(
  world_face : @shape.FaceName,
  state : UInt,
) -> @shape.FaceName {
  source_face_table[table_index(state, world_face)]
}

///|
pub fn SixFacing::face_layer(
  faces : @shape.FaceLayerIndices,
  state : UInt,
  world_face : @shape.FaceName,
) -> Int {
  let source_face = SixFacing::source_face_for_world_face(world_face, state)
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
fn face_flip_v(face : @shape.FaceName) -> Bool {
  match face {
    @shape.FaceName::PosX
    | @shape.FaceName::NegX
    | @shape.FaceName::PosZ
    | @shape.FaceName::NegZ => true
    _ => false
  }
}

///|
/// Rotate source-space direction into world-space for the given facing state.
fn rotate_dir_by_state(state : UInt, dir : (Int, Int, Int)) -> (Int, Int, Int) {
  let (x, y, z) = dir
  match state.reinterpret_as_int() {
    1 => (-x, y, -z)
    2 => (-y, x, z)
    3 => (y, -x, z)
    4 => (-z, y, x)
    5 => (z, y, -x)
    _ => (x, y, z)
  }
}

///|
fn face_dir(face : @shape.FaceName) -> (Int, Int, Int) {
  match face {
    @shape.FaceName::PosX => (1, 0, 0)
    @shape.FaceName::NegX => (-1, 0, 0)
    @shape.FaceName::PosY => (0, 1, 0)
    @shape.FaceName::NegY => (0, -1, 0)
    @shape.FaceName::PosZ => (0, 0, 1)
    @shape.FaceName::NegZ => (0, 0, -1)
  }
}

///|
fn face_geom_by_name(face : @shape.FaceName) -> @shape.FaceGeom {
  @shape.faces[face_index(face)]
}

///|
fn dir_neg(dir : (Int, Int, Int)) -> (Int, Int, Int) {
  let (x, y, z) = dir
  (-x, -y, -z)
}

///|
fn dir_eq(a : (Int, Int, Int), b : (Int, Int, Int)) -> Bool {
  let (ax, ay, az) = a
  let (bx, by, bz) = b
  ax == bx && ay == by && az == bz
}

///|
fn dir_dot(a : (Int, Int, Int), b : (Int, Int, Int)) -> Int {
  let (ax, ay, az) = a
  let (bx, by, bz) = b
  ax * bx + ay * by + az * bz
}

///|
fn dir_cross(a : (Int, Int, Int), b : (Int, Int, Int)) -> (Int, Int, Int) {
  let (ax, ay, az) = a
  let (bx, by, bz) = b
  (ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx)
}

///|
/// Rotate `dir` around axis `axis` by +90° (right-hand rule).
fn rotate_dir_90(
  axis : (Int, Int, Int),
  dir : (Int, Int, Int),
) -> (Int, Int, Int) {
  let dot = dir_dot(axis, dir)
  let (cx, cy, cz) = dir_cross(axis, dir)
  let (ax, ay, az) = axis
  (cx + ax * dot, cy + ay * dot, cz + az * dot)
}

///|
fn rotate_dir_about_axis_quarters(
  axis : (Int, Int, Int),
  quarters : Int,
  dir : (Int, Int, Int),
) -> (Int, Int, Int) {
  match quarters {
    1 => rotate_dir_90(axis, dir)
    2 => rotate_dir_90(axis, rotate_dir_90(axis, dir))
    3 => rotate_dir_90(axis, rotate_dir_90(axis, rotate_dir_90(axis, dir)))
    _ => dir
  }
}

///|
/// Canonical UV roll for source-space faces when front is +X.
/// This matches the expected cube texturing convention used by
/// direction-sensitive side textures (e.g. piston side).
fn source_face_roll_quarters(face : @shape.FaceName) -> Int {
  match face {
    @shape.FaceName::PosZ => 1
    @shape.FaceName::NegZ => 3
    @shape.FaceName::PosY | @shape.FaceName::NegY => 2
    _ => 0
  }
}

///|
/// Extra per-world-face correction:
/// when facing ±Y, only world Z side faces need +180deg.
fn world_face_extra_roll_quarters(
  state : UInt,
  world_face : @shape.FaceName,
) -> Int {
  match state.reinterpret_as_int() {
    2 | 3 =>
      match world_face {
        @shape.FaceName::PosZ | @shape.FaceName::NegZ => 2
        _ => 0
      }
    _ => 0
  }
}

///|
fn face_uv_axes(face : @shape.FaceName) -> ((Int, Int, Int), (Int, Int, Int)) {
  let geom = face_geom_by_name(face)
  let (ax, ay, az) = geom.corners[0]
  let (bx, by, bz) = geom.corners[1]
  let (dx, dy, dz) = geom.corners[3]
  ((bx - ax, by - ay, bz - az), (dx - ax, dy - ay, dz - az))
}

///|
/// Solve texture transform flags so six-way facing keeps texture orientation
/// consistent with the oriented source face.
fn calc_uv_transform(
  world_face : @shape.FaceName,
  state : UInt,
) -> (Bool, Bool, Bool) {
  let source_face = SixFacing::source_face_for_world_face(world_face, state)
  let (source_u_raw, source_v_raw) = face_uv_axes(source_face)
  let source_u0 = rotate_dir_by_state(state, source_u_raw)
  let source_v0 = rotate_dir_by_state(state, source_v_raw)
  let source_v_base = if face_flip_v(source_face) {
    dir_neg(source_v0)
  } else {
    source_v0
  }
  let roll_axis = rotate_dir_by_state(state, face_dir(source_face))
  let roll = source_face_roll_quarters(source_face)
  let source_u = rotate_dir_about_axis_quarters(roll_axis, roll, source_u0)
  let source_v = rotate_dir_about_axis_quarters(roll_axis, roll, source_v_base)
  let (world_u, world_v_raw) = face_uv_axes(world_face)
  let world_v = if face_flip_v(world_face) {
    dir_neg(world_v_raw)
  } else {
    world_v_raw
  }
  let world_roll = world_face_extra_roll_quarters(state, world_face)
  let world_axis = face_dir(world_face)
  let world_u2 = rotate_dir_about_axis_quarters(world_axis, world_roll, world_u)
  let world_v2 = rotate_dir_about_axis_quarters(world_axis, world_roll, world_v)
  for rotate in [false, true] {
    for flip_u in [false, true] {
      for flip_v in [false, true] {
        let (ru0, rv0) = if rotate {
          (world_v2, dir_neg(world_u2))
        } else {
          (world_u2, world_v2)
        }
        let ru = if flip_u { dir_neg(ru0) } else { ru0 }
        let rv = if flip_v { dir_neg(rv0) } else { rv0 }
        if dir_eq(ru, source_u) && dir_eq(rv, source_v) {
          return (rotate, flip_u, flip_v)
        }
      }
    }
  }
  (false, false, false)
}

///|
let uv_transform_table : Array[(Bool, Bool, Bool)] = {
  let table = Array::make(
    SIX_FACING_FACE_COUNT * SIX_FACING_FACE_COUNT,
    (false, false, false),
  )
  for state in all_states {
    for face in all_faces {
      table[table_index(state, face)] = calc_uv_transform(face, state)
    }
  }
  table
}

///|
fn solve_uv_transform(
  world_face : @shape.FaceName,
  state : UInt,
) -> (Bool, Bool, Bool) {
  uv_transform_table[table_index(state, world_face)]
}

///|
fn uv_rect_with_flips(
  flip_u : Bool,
  flip_v : Bool,
) -> (Float, Float, Float, Float) {
  let u0 = if flip_u { 1.0F } else { 0.0F }
  let u1 = if flip_u { 0.0F } else { 1.0F }
  let v0 = if flip_v { 1.0F } else { 0.0F }
  let v1 = if flip_v { 0.0F } else { 1.0F }
  (u0, v0, u1, v1)
}

///|
pub let six_facing_model : @shape.Model = @shape.Model::{
  face_layer: fn(info : @shape.FaceSource, world_face : @shape.FaceName) {
    SixFacing::face_layer(info.faces, info.state, world_face)
  },
  face_box: default_model.face_box,
  uv_rect: fn(info : @shape.FaceSource, world_face : @shape.FaceName) {
    let (_, flip_u, flip_v) = solve_uv_transform(world_face, info.state)
    uv_rect_with_flips(flip_u, flip_v)
  },
  rotate_uv: fn(info : @shape.FaceSource, face : @shape.FaceGeom) {
    let (rotate, _, _) = solve_uv_transform(face.name, info.state)
    rotate
  },
  double_sided: default_model.double_sided,
  face_visible: default_model.face_visible,
  emit_mesh: default_model.emit_mesh,
  emit_colors: default_model.emit_colors,
}
