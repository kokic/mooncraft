///|
pub let redstone_torch_glow_min : Float = 6.5F / 16.0F

///|
pub let redstone_torch_glow_max : Float = 9.5F / 16.0F

///|
pub let redstone_torch_glow_y_min : Float = 7.5F / 16.0F

///|
pub let redstone_torch_glow_y_max : Float = 10.5F / 16.0F

///|
pub let redstone_torch_uv_up : (Float, Float, Float, Float) = @util.offset_uv_pixels(
  8, 5, 1, 1,
)

///|
pub let redstone_torch_uv_down : (Float, Float, Float, Float) = @util.offset_uv_pixels(
  7, 5, 1, 1,
)

///|
pub let redstone_torch_uv_north : (Float, Float, Float, Float) = @util.offset_uv_pixels(
  6, 6, 1, 1,
)

///|
pub let redstone_torch_uv_south : (Float, Float, Float, Float) = @util.offset_uv_pixels(
  9, 6, 1, 1,
)

///|
pub let redstone_torch_uv_west : (Float, Float, Float, Float) = @util.offset_uv_pixels(
  6, 7, 1, 1,
)

///|
pub let redstone_torch_uv_east : (Float, Float, Float, Float) = @util.offset_uv_pixels(
  9, 7, 1, 1,
)

///|
pub fn Torch::append_classic_mesh(
  state : UInt,
  layer_f : Float,
  bx : Float,
  by : Float,
  bz : Float,
  push_face_rev : (
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
  let shade_xp = @util.face_shade_scale(1, 0, 0)
  let shade_xn = @util.face_shade_scale(-1, 0, 0)
  let shade_yp = @util.face_shade_scale(0, 1, 0)
  let shade_yn = @util.face_shade_scale(0, -1, 0)
  let shade_zp = @util.face_shade_scale(0, 0, 1)
  let shade_zn = @util.face_shade_scale(0, 0, -1)
  push_face(
    transform.apply((x0, y1, z1), bx, by, bz),
    transform.apply((x0, y1, z0), bx, by, bz),
    transform.apply((x1, y1, z0), bx, by, bz),
    transform.apply((x1, y1, z1), bx, by, bz),
    (0, 1, 0),
    layer_f,
    classic_torch_uv_top,
    false,
    shade_yp,
  )
  push_face(
    transform.apply((x0, y0, z0), bx, by, bz),
    transform.apply((x0, y0, z1), bx, by, bz),
    transform.apply((x1, y0, z1), bx, by, bz),
    transform.apply((x1, y0, z0), bx, by, bz),
    (0, -1, 0),
    layer_f,
    classic_torch_uv_bottom,
    false,
    shade_yn,
  )
  let py0 = 0.0F
  let py1 = 1.0F
  let pz0 = 0.0F
  let pz1 = 1.0F
  push_face(
    transform.apply((x1, py0, pz0), bx, by, bz),
    transform.apply((x1, py0, pz1), bx, by, bz),
    transform.apply((x1, py1, pz1), bx, by, bz),
    transform.apply((x1, py1, pz0), bx, by, bz),
    (1, 0, 0),
    layer_f,
    classic_torch_uv_full,
    true,
    shade_xp,
  )
  push_face_rev(
    transform.apply((x1, py0, pz0), bx, by, bz),
    transform.apply((x1, py0, pz1), bx, by, bz),
    transform.apply((x1, py1, pz1), bx, by, bz),
    transform.apply((x1, py1, pz0), bx, by, bz),
    (-1, 0, 0),
    layer_f,
    classic_torch_uv_full,
    true,
    shade_xn,
  )
  push_face(
    transform.apply((x0, py0, pz1), bx, by, bz),
    transform.apply((x0, py0, pz0), bx, by, bz),
    transform.apply((x0, py1, pz0), bx, by, bz),
    transform.apply((x0, py1, pz1), bx, by, bz),
    (-1, 0, 0),
    layer_f,
    classic_torch_uv_full,
    true,
    shade_xn,
  )
  push_face_rev(
    transform.apply((x0, py0, pz1), bx, by, bz),
    transform.apply((x0, py0, pz0), bx, by, bz),
    transform.apply((x0, py1, pz0), bx, by, bz),
    transform.apply((x0, py1, pz1), bx, by, bz),
    (1, 0, 0),
    layer_f,
    classic_torch_uv_full,
    true,
    shade_xp,
  )
  let px0 = 0.0F
  let px1 = 1.0F
  push_face(
    transform.apply((px1, py0, z0), bx, by, bz),
    transform.apply((px0, py0, z0), bx, by, bz),
    transform.apply((px0, py1, z0), bx, by, bz),
    transform.apply((px1, py1, z0), bx, by, bz),
    (0, 0, 1),
    layer_f,
    classic_torch_uv_full,
    true,
    shade_zp,
  )
  push_face_rev(
    transform.apply((px1, py0, z0), bx, by, bz),
    transform.apply((px0, py0, z0), bx, by, bz),
    transform.apply((px0, py1, z0), bx, by, bz),
    transform.apply((px1, py1, z0), bx, by, bz),
    (0, 0, -1),
    layer_f,
    classic_torch_uv_full,
    true,
    shade_zn,
  )
  push_face(
    transform.apply((px0, py0, z1), bx, by, bz),
    transform.apply((px1, py0, z1), bx, by, bz),
    transform.apply((px1, py1, z1), bx, by, bz),
    transform.apply((px0, py1, z1), bx, by, bz),
    (0, 0, -1),
    layer_f,
    classic_torch_uv_full,
    true,
    shade_zn,
  )
  push_face_rev(
    transform.apply((px0, py0, z1), bx, by, bz),
    transform.apply((px1, py0, z1), bx, by, bz),
    transform.apply((px1, py1, z1), bx, by, bz),
    transform.apply((px0, py1, z1), bx, by, bz),
    (0, 0, 1),
    layer_f,
    classic_torch_uv_full,
    true,
    shade_zp,
  )
}

///|
pub fn Torch::append_redstone_mesh(
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
  Torch::append_mesh(state, layer_f, bx, by, bz, push_face)
  let transform = TorchTransform::from(state.reinterpret_as_int())
  let shade_xp = @util.face_shade_scale(1, 0, 0)
  let shade_xn = @util.face_shade_scale(-1, 0, 0)
  let shade_yp = @util.face_shade_scale(0, 1, 0)
  let shade_yn = @util.face_shade_scale(0, -1, 0)
  let shade_zp = @util.face_shade_scale(0, 0, 1)
  let shade_zn = @util.face_shade_scale(0, 0, -1)
  let gx0 = redstone_torch_glow_min
  let gx1 = redstone_torch_glow_max
  let gy0 = redstone_torch_glow_y_min
  let gy1 = redstone_torch_glow_y_max
  let gz0 = redstone_torch_glow_min
  let gz1 = redstone_torch_glow_max
  push_face(
    transform.apply((gx0, gy0, gz1), bx, by, bz),
    transform.apply((gx0, gy0, gz0), bx, by, bz),
    transform.apply((gx1, gy0, gz0), bx, by, bz),
    transform.apply((gx1, gy0, gz1), bx, by, bz),
    (0, 1, 0),
    layer_f,
    redstone_torch_uv_up,
    false,
    shade_yp,
  )
  push_face(
    transform.apply((gx0, gy1, gz0), bx, by, bz),
    transform.apply((gx0, gy1, gz1), bx, by, bz),
    transform.apply((gx1, gy1, gz1), bx, by, bz),
    transform.apply((gx1, gy1, gz0), bx, by, bz),
    (0, -1, 0),
    layer_f,
    redstone_torch_uv_down,
    false,
    shade_yn,
  )
  push_face(
    transform.apply((gx1, gy0, gz0), bx, by, bz),
    transform.apply((gx0, gy0, gz0), bx, by, bz),
    transform.apply((gx0, gy1, gz0), bx, by, bz),
    transform.apply((gx1, gy1, gz0), bx, by, bz),
    (0, 0, 1),
    layer_f,
    redstone_torch_uv_south,
    true,
    shade_zp,
  )
  push_face(
    transform.apply((gx0, gy0, gz1), bx, by, bz),
    transform.apply((gx1, gy0, gz1), bx, by, bz),
    transform.apply((gx1, gy1, gz1), bx, by, bz),
    transform.apply((gx0, gy1, gz1), bx, by, bz),
    (0, 0, -1),
    layer_f,
    redstone_torch_uv_north,
    true,
    shade_zn,
  )
  push_face(
    transform.apply((gx0, gy0, gz0), bx, by, bz),
    transform.apply((gx0, gy0, gz1), bx, by, bz),
    transform.apply((gx0, gy1, gz1), bx, by, bz),
    transform.apply((gx0, gy1, gz0), bx, by, bz),
    (1, 0, 0),
    layer_f,
    redstone_torch_uv_east,
    true,
    shade_xp,
  )
  push_face(
    transform.apply((gx1, gy0, gz1), bx, by, bz),
    transform.apply((gx1, gy0, gz0), bx, by, bz),
    transform.apply((gx1, gy1, gz0), bx, by, bz),
    transform.apply((gx1, gy1, gz1), bx, by, bz),
    (-1, 0, 0),
    layer_f,
    redstone_torch_uv_west,
    true,
    shade_xn,
  )
}

///|
pub fn Torch::append_redstone_colors(push_color : (Int, Float) -> Unit) -> Unit {
  Torch::append_colors(push_color)
  let shade_xp = @util.face_shade_scale(1, 0, 0)
  let shade_xn = @util.face_shade_scale(-1, 0, 0)
  let shade_yp = @util.face_shade_scale(0, 1, 0)
  let shade_yn = @util.face_shade_scale(0, -1, 0)
  let shade_zp = @util.face_shade_scale(0, 0, 1)
  let shade_zn = @util.face_shade_scale(0, 0, -1)
  push_color(6, shade_yp)
  push_color(6, shade_yn)
  push_color(6, shade_zp)
  push_color(6, shade_zn)
  push_color(6, shade_xp)
  push_color(6, shade_xn)
}

///|
fn emit_redstone_torch_mesh(
  info : @shape.FaceSource,
  bx : Float,
  by : Float,
  bz : Float,
  push_face : @shape.FaceEmitter,
  _push_face_rev : @shape.FaceEmitter,
) -> Bool {
  let layer_f = Float::from_int(info.faces.pos_x)
  Torch::append_redstone_mesh(info.state, layer_f, bx, by, bz, push_face)
  true
}

///|
fn emit_redstone_torch_colors(
  _info : @shape.FaceSource,
  push_color : @shape.ColorEmitter,
) -> Bool {
  Torch::append_redstone_colors(push_color)
  true
}

///|
fn emit_redstone_classic_mesh(
  info : @shape.FaceSource,
  bx : Float,
  by : Float,
  bz : Float,
  push_face : @shape.FaceEmitter,
  push_face_rev : @shape.FaceEmitter,
) -> Bool {
  let layer_f = Float::from_int(info.faces.pos_x)
  Torch::append_classic_mesh(info.state, layer_f, bx, by, bz, push_face_rev, push_face)
  true
}

///|
fn emit_redstone_classic_colors(
  _info : @shape.FaceSource,
  push_color : @shape.ColorEmitter,
) -> Bool {
  Torch::append_classic_colors(push_color)
  true
}

///|
pub let redstone_torch_model : @shape.Model = @shape.Model::{
  face_layer: face_layer_default,
  face_box: face_box_none,
  uv_rect: uv_rect_default,
  rotate_uv: rotate_uv_none,
  double_sided: double_sided_false,
  emit_mesh: emit_redstone_torch_mesh,
  emit_colors: emit_redstone_torch_colors,
}

///|
pub let redstone_torch_classic_model : @shape.Model = @shape.Model::{
  face_layer: face_layer_default,
  face_box: face_box_none,
  uv_rect: uv_rect_default,
  rotate_uv: rotate_uv_none,
  double_sided: double_sided_false,
  emit_mesh: emit_redstone_classic_mesh,
  emit_colors: emit_redstone_classic_colors,
}
