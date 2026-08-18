///|
pub type Torch

///|
pub fn Torch::unique_name(base : String, state : UInt) -> String {
  match state {
    1 => "\{base}:north"
    2 => "\{base}:south"
    3 => "\{base}:west"
    4 => "\{base}:east"
    _ => "\{base}"
  }
}

///|
fn torch_state_from_face(face : @shape.FaceName) -> UInt {
  match face {
    @shape.FaceName::PosZ => 1
    @shape.FaceName::NegZ => 2
    @shape.FaceName::PosX => 3
    @shape.FaceName::NegX => 4
    _ => 0
  }
}

///|
/// Infer torch placement state from the target block and the previous hit.
pub fn Torch::torch_state_from_placement(
  block : Array[Int],
  prev : Array[Int],
) -> UInt {
  @shape.FaceName::from_adjacent_blocks(block, prev)
  .map(torch_state_from_face)
  .unwrap_or(0)
}

///|
/// Due to the size (X / Z) of the torch model, this value is at least 2
const TORCH_BOUNDS_SIZE : Float = 3.0F

///|
const TORCH_WALL_FACE_BOUNDS_SIZE = 5.0F

///|
const TORCH_WALL_HORIZONTAL_BOUNDS_SIZE = 3.0F

///|
pub fn Torch::collect_bounds() -> Array[Array[Float]] {
  let face = TORCH_WALL_FACE_BOUNDS_SIZE / 16
  let half = TORCH_BOUNDS_SIZE / 2.0F
  let floor_min = [(8.0F - half) / 16, 0.0F, (8.0F - half) / 16]
  let floor_max = [(8.0F + half) / 16, 10.0F / 16, (8.0F + half) / 16]

  // on the side
  let wall_y_min = 3.0F / 16
  let wall_y_max = 13.0F / 16
  let wall_half = TORCH_WALL_HORIZONTAL_BOUNDS_SIZE / 2.0F
  let wall_min = (8.0F - wall_half) / 16
  let wall_max = (8.0F + wall_half) / 16
  let north_min = [wall_min, wall_y_min, 0.0F]
  let north_max = [wall_max, wall_y_max, face]
  let south_min = [wall_min, wall_y_min, (16 - 5.0F) / 16]
  let south_max = [wall_max, wall_y_max, 1.0F]
  let west_min = [0.0F, wall_y_min, wall_min]
  let west_max = [face, wall_y_max, wall_max]
  let east_min = [(16.0F - 5.0F) / 16, wall_y_min, wall_min]
  let east_max = [1.0F, wall_y_max, wall_max]
  [
    floor_min, floor_max, north_min, north_max, south_min, south_max, west_min, west_max,
    east_min, east_max,
  ]
}

///|
pub fn Torch::get_outline_pad() -> @util.AABB {
  let v = 0.5F / 16
  @util.AABB::{ sx: v, sy: 0, sz: v, ex: v, ey: -v, ez: v }
}

///|
pub const TORCH_MIN : Float = 0.4375F // 7.0F / 16.0F

///|
pub let torch_min : Float = TORCH_MIN

///|
pub let torch_max : Float = 9.0F / 16.0F

///|
pub let torch_top : Float = 10.0F / 16.0F

///|
pub let torch_uv_side : (Float, Float, Float, Float) = @util.rect_uv_pixels(
  7, 6, 8, 15,
)

///|
pub let torch_uv_top : (Float, Float, Float, Float) = @util.offset_uv_pixels(
  7, 6, 2, 2,
)

///|
pub let torch_uv_bottom : (Float, Float, Float, Float) = @util.offset_uv_pixels(
  7, 14, 2, 2,
)

///|
pub let torch_tilt : Float = Float::from_double(@math.PI / 8)

///|
pub let torch_offset : Float = 7.0F / 16.0F

///|
pub let torch_wall_y_offset : Float = 3.0F / 16.0F

///|
pub let torch_pivot : (Float, Float, Float) = (0.5F, 2.0F / 16.0F, 0.5F)

///|
struct TorchTransform {
  cos_x : Float
  sin_x : Float
  cos_z : Float
  sin_z : Float
  off_x : Float
  off_y : Float
  off_z : Float
}

///|
pub fn TorchTransform::from(state : Int) -> TorchTransform {
  let mut rot_x = 0.0F
  let mut rot_z = 0.0F
  let mut off_x = 0.0F
  let mut off_y = 0.0F
  let mut off_z = 0.0F
  match state {
    // wall north (z-)
    1 => {
      rot_x = torch_tilt
      off_z = -torch_offset
      off_y = torch_wall_y_offset
    }
    // wall south (z+)
    2 => {
      rot_x = -torch_tilt
      off_z = torch_offset
      off_y = torch_wall_y_offset
    }
    // wall west (x-)
    3 => {
      rot_z = -torch_tilt
      off_x = -torch_offset
      off_y = torch_wall_y_offset
    }
    // wall east (x+)
    4 => {
      rot_z = torch_tilt
      off_x = torch_offset
      off_y = torch_wall_y_offset
    }
    _ => ()
  }
  TorchTransform::{
    cos_x: Float::from_double(@math.cos(rot_x.to_double())),
    sin_x: Float::from_double(@math.sin(rot_x.to_double())),
    cos_z: Float::from_double(@math.cos(rot_z.to_double())),
    sin_z: Float::from_double(@math.sin(rot_z.to_double())),
    off_x,
    off_y,
    off_z,
  }
}

///|
pub fn TorchTransform::apply(
  t : TorchTransform,
  v : (Float, Float, Float),
  bx : Float,
  by : Float,
  bz : Float,
) -> (Float, Float, Float) {
  let (vx, vy, vz) = v
  let (pvx, pvy, pvz) = torch_pivot
  let mut lx = vx - pvx
  let mut ly = vy - pvy
  let mut lz = vz - pvz
  if t.sin_x != 0.0F || t.cos_x != 1.0F {
    let ny = ly * t.cos_x - lz * t.sin_x
    let nz = ly * t.sin_x + lz * t.cos_x
    ly = ny
    lz = nz
  }
  if t.sin_z != 0.0F || t.cos_z != 1.0F {
    let nx = lx * t.cos_z - ly * t.sin_z
    let ny = lx * t.sin_z + ly * t.cos_z
    lx = nx
    ly = ny
  }
  (lx + pvx + t.off_x + bx, ly + pvy + t.off_y + by, lz + pvz + t.off_z + bz)
}

///|

///|
let classic_torch_uv_full : (Float, Float, Float, Float) = @util.offset_uv_pixels(
  0, 0, 16, 16,
)

///|
let classic_torch_uv_top : (Float, Float, Float, Float) = @util.offset_uv_pixels(
  7, 6, 2, 2,
)

///|
let classic_torch_uv_bottom : (Float, Float, Float, Float) = @util.offset_uv_pixels(
  7, 13, 2, 2,
)

///|
/// Per-face shade scales in normal order (xp, xn, yp, yn, zp, zn).
fn face_shades() -> (Float, Float, Float, Float, Float, Float) {
  (
    @util.face_shade_scale(1, 0, 0),
    @util.face_shade_scale(-1, 0, 0),
    @util.face_shade_scale(0, 1, 0),
    @util.face_shade_scale(0, -1, 0),
    @util.face_shade_scale(0, 0, 1),
    @util.face_shade_scale(0, 0, -1),
  )
}

///|
pub fn Torch::append_mesh(
  state : UInt,
  layer_f : Float,
  bx : Float,
  by : Float,
  bz : Float,
  push_face : (
    (Float, Float, Float),
    (Float, Float, Float),
    (Float, Float, Float),
    (Float, Float, Float),
    (Int, Int, Int),
    Float,
    (Float, Float, Float, Float),
    Bool,
    Float,
  ) -> Unit,
) -> Unit {
  let x0 = torch_min
  let x1 = torch_max
  let y0 = 0.0F
  let y1 = torch_top
  let z0 = torch_min
  let z1 = torch_max
  let transform = TorchTransform::from(state.reinterpret_as_int())
  let (shade_xp, shade_xn, shade_yp, shade_yn, shade_zp, shade_zn) = face_shades()
  let push = fn(
    corners : Array[(Float, Float, Float)],
    normal : (Int, Int, Int),
    uv_rect : (Float, Float, Float, Float),
    flip_v : Bool,
    shade : Float,
  ) -> Unit {
    push_face(
      transform.apply(corners[0], bx, by, bz),
      transform.apply(corners[1], bx, by, bz),
      transform.apply(corners[2], bx, by, bz),
      transform.apply(corners[3], bx, by, bz),
      normal,
      layer_f,
      uv_rect,
      flip_v,
      shade,
    )
  }
  push(
    [(x1, y0, z0), (x1, y0, z1), (x1, y1, z1), (x1, y1, z0)],
    (1, 0, 0),
    torch_uv_side,
    true,
    shade_xp,
  )
  push(
    [(x0, y0, z1), (x0, y0, z0), (x0, y1, z0), (x0, y1, z1)],
    (-1, 0, 0),
    torch_uv_side,
    true,
    shade_xn,
  )
  push(
    [(x0, y1, z1), (x0, y1, z0), (x1, y1, z0), (x1, y1, z1)],
    (0, 1, 0),
    torch_uv_top,
    false,
    shade_yp,
  )
  push(
    [(x0, y0, z0), (x0, y0, z1), (x1, y0, z1), (x1, y0, z0)],
    (0, -1, 0),
    torch_uv_bottom,
    false,
    shade_yn,
  )
  push(
    [(x1, y0, z1), (x0, y0, z1), (x0, y1, z1), (x1, y1, z1)],
    (0, 0, 1),
    torch_uv_side,
    true,
    shade_zp,
  )
  push(
    [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)],
    (0, 0, -1),
    torch_uv_side,
    true,
    shade_zn,
  )
}

///|
pub fn Torch::append_colors(push_color : (Int, Float) -> Unit) -> Unit {
  let (shade_xp, shade_xn, shade_yp, shade_yn, shade_zp, shade_zn) = face_shades()
  push_color(6, shade_xp)
  push_color(6, shade_xn)
  push_color(6, shade_yp)
  push_color(6, shade_yn)
  push_color(6, shade_zp)
  push_color(6, shade_zn)
}

///|
pub fn Torch::append_classic_colors(push_color : (Int, Float) -> Unit) -> Unit {
  let (shade_xp, shade_xn, shade_yp, shade_yn, shade_zp, shade_zn) = face_shades()
  push_color(6, shade_yp)
  push_color(6, shade_yn)
  push_color(6, shade_xp)
  push_color(6, shade_xn)
  push_color(6, shade_zp)
  push_color(6, shade_zn)
  push_color(6, shade_xn)
  push_color(6, shade_xp)
  push_color(6, shade_zn)
  push_color(6, shade_zp)
}

///|
fn emit_torch_mesh(
  info : @shape.FaceSource,
  bx : Float,
  by : Float,
  bz : Float,
  push_face : @shape.FaceEmitter,
  _push_face_rev : @shape.FaceEmitter,
) -> Bool {
  let layer_f = Float::from_int(info.faces.pos_x)
  Torch::append_mesh(info.state, layer_f, bx, by, bz, push_face)
  true
}

///|
fn emit_torch_colors(
  _info : @shape.FaceSource,
  push_color : @shape.ColorEmitter,
) -> Bool {
  Torch::append_colors(push_color)
  true
}

///|
pub let torch_model : @shape.Model = @shape.Model::{
  face_layer: face_layer_default,
  face_box: face_box_none,
  uv_rect: uv_rect_default,
  rotate_uv: rotate_uv_none,
  double_sided: double_sided_false,
  face_visible: fn(
    info : @shape.FaceSource,
    face : @shape.FaceGeom,
    occlusion : @shape.FaceOcclusion,
  ) {
    face_visible_default(face_box_none, info, face, occlusion)
  },
  emit_mesh: emit_torch_mesh,
  emit_colors: emit_torch_colors,
}

///|
pub fn torch_bounds_index(state : UInt) -> Int {
  match state.reinterpret_as_int() {
    1 => 2 // north
    2 => 4 // south
    3 => 6 // west
    4 => 8 // east
    _ => 0 // floor
  }
}

///|
pub fn Torch::shape_box_by_state(state : UInt) -> @shape.Box {
  let bounds = Torch::collect_bounds()
  let idx = torch_bounds_index(state)
  @shape.Box::{ min: bounds[idx], max: bounds[idx + 1] }
}
