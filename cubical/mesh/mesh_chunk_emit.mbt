///|
let face_uvs_base : Array[(Float, Float)] = [
  (0, 0),
  (1, 0),
  (1, 1),
  (0, 0),
  (1, 1),
  (0, 1),
]

///|
let face_uvs_rot90 : Array[(Float, Float)] = face_uvs_base.map(uv => {
  let (u, v) = uv
  (v, 1.0F - u)
})

///|
let face_uvs_rev : Array[(Float, Float)] = [
  (0, 0),
  (1, 1),
  (1, 0),
  (0, 0),
  (0, 1),
  (1, 1),
]

///|
/// The vertex arrays a builder writes into. `normals` is `Some` when the
/// builder emits flat per-face normals alongside the geometry.
priv struct MeshFaceArrays {
  positions : Array[Float]
  uvs : Array[Float]
  layers : Array[Float]
  colors : Array[Float]
  normals : Array[Float]?
}

///|
fn flip_uv_for(face : @shape.FaceName) -> Bool {
  match face {
    @shape.FaceName::PosX
    | @shape.FaceName::NegX
    | @shape.FaceName::PosZ
    | @shape.FaceName::NegZ => true
    _ => false
  }
}

///|
/// Emit one quad (6 vertices) into the target arrays.
fn emit_face_vertices(
  arrays : MeshFaceArrays,
  face_normal : (Int, Int, Int),
  verts : Array[(Float, Float, Float)],
  uv_base : Array[(Float, Float)],
  uv_rect : (Float, Float, Float, Float),
  flip_v : Bool,
  layer_f : Float,
  tint : (Float, Float, Float, Float),
  color_scale : Float,
  alpha_scale : Float,
) -> Unit {
  let (u0, v0, u1, v1) = uv_rect
  let (tr, tg, tb, ta) = tint
  let (nx, ny, nz) = face_normal
  for i in 0..<6 {
    let (vx, vy, vz) = verts[i]
    arrays.positions.push(vx)
    arrays.positions.push(vy)
    arrays.positions.push(vz)
    arrays.colors.push(color_scale * tr)
    arrays.colors.push(color_scale * tg)
    arrays.colors.push(color_scale * tb)
    arrays.colors.push(ta * alpha_scale)
    if arrays.normals is Some(normals) {
      normals.push(Float::from_int(nx))
      normals.push(Float::from_int(ny))
      normals.push(Float::from_int(nz))
    }
    let (bu, bv) = uv_base[i]
    let v = if flip_v { 1.0F - bv } else { bv }
    let u = u0 + bu * (u1 - u0)
    let v2 = v0 + v * (v1 - v0)
    arrays.uvs.push(u)
    arrays.uvs.push(v2)
    arrays.layers.push(layer_f)
  }
}

///|
fn emit_face(
  arrays : MeshFaceArrays,
  a : (Float, Float, Float),
  b : (Float, Float, Float),
  c : (Float, Float, Float),
  d : (Float, Float, Float),
  normal : (Int, Int, Int),
  uv_rect : (Float, Float, Float, Float),
  flip_v : Bool,
  layer_f : Float,
  tint : (Float, Float, Float, Float),
  color_scale : Float,
  alpha_scale : Float,
) -> Unit {
  emit_face_vertices(
    arrays,
    normal,
    [a, b, c, a, c, d],
    face_uvs_base,
    uv_rect,
    flip_v,
    layer_f,
    tint,
    color_scale,
    alpha_scale,
  )
}

///|
fn emit_reversed_face(
  arrays : MeshFaceArrays,
  a : (Float, Float, Float),
  b : (Float, Float, Float),
  c : (Float, Float, Float),
  d : (Float, Float, Float),
  normal : (Int, Int, Int),
  uv_rect : (Float, Float, Float, Float),
  flip_v : Bool,
  layer_f : Float,
  tint : (Float, Float, Float, Float),
  color_scale : Float,
  alpha_scale : Float,
) -> Unit {
  emit_face_vertices(
    arrays,
    normal,
    [a, c, b, a, d, c],
    face_uvs_rev,
    uv_rect,
    flip_v,
    layer_f,
    tint,
    color_scale,
    alpha_scale,
  )
}

///|
fn emit_face_cube(
  arrays : MeshFaceArrays,
  rotate_uv : Bool,
  a : (Float, Float, Float),
  b : (Float, Float, Float),
  c : (Float, Float, Float),
  d : (Float, Float, Float),
  normal : (Int, Int, Int),
  uv_rect : (Float, Float, Float, Float),
  flip_v : Bool,
  layer_f : Float,
  tint : (Float, Float, Float, Float),
  color_scale : Float,
  alpha_scale : Float,
) -> Unit {
  let uv_base = if rotate_uv { face_uvs_rot90 } else { face_uvs_base }
  emit_face_vertices(
    arrays,
    normal,
    [a, b, c, a, c, d],
    uv_base,
    uv_rect,
    flip_v,
    layer_f,
    tint,
    color_scale,
    alpha_scale,
  )
}

///|
/// Emit the cube faces of one block into the target arrays.
fn emit_model_faces(
  chunk : PaddedChunk,
  arrays : MeshFaceArrays,
  render_block : @block.RenderBlock,
  x : Int,
  y : Int,
  z : Int,
) -> Unit {
  let model = render_block.block.model
  let render_info = @shape.FaceSource::{
    faces: render_block.faces,
    state: render_block.block.state,
  }
  let bx = Float::from_int(x)
  let by = Float::from_int(y)
  let bz = Float::from_int(z)
  let tint = render_block.block.tint
  let emit_face = (
    a : (Float, Float, Float),
    b : (Float, Float, Float),
    c : (Float, Float, Float),
    d : (Float, Float, Float),
    normal : (Int, Int, Int),
    layer_f : Float,
    uv_rect : (Float, Float, Float, Float),
    flip_v : Bool,
    color_scale : Float,
  ) => {
    emit_face(
      arrays, a, b, c, d, normal, uv_rect, flip_v, layer_f, tint, color_scale, 1.0F,
    )
  }
  let emit_face_rev = (
    a : (Float, Float, Float),
    b : (Float, Float, Float),
    c : (Float, Float, Float),
    d : (Float, Float, Float),
    normal : (Int, Int, Int),
    layer_f : Float,
    uv_rect : (Float, Float, Float, Float),
    flip_v : Bool,
    color_scale : Float,
  ) => {
    emit_reversed_face(
      arrays, a, b, c, d, normal, uv_rect, flip_v, layer_f, tint, color_scale, 1.0F,
    )
  }
  if (model.emit_mesh)(render_info, bx, by, bz, emit_face, emit_face_rev) {
    return
  }
  let is_double_sided = (model.double_sided)(render_info)
  for face in @shape.faces {
    guard face_lighting(chunk, model, render_info, face, render_block, x, y, z)
      is Some(lighting) else {
      continue
    }
    let custom_box = (model.face_box)(render_info, face.name)
    let (a, b, c, d) = face_corners_world(face, x, y, z, custom_box)
    let rotate_uv = (model.rotate_uv)(render_info, face)
    let uv_rect = (model.uv_rect)(render_info, face.name)
    let layer_f = Float::from_int((model.face_layer)(render_info, face.name))
    let flip_v = flip_uv_for(face.name)
    emit_face_cube(
      arrays,
      rotate_uv,
      a,
      b,
      c,
      d,
      face.normal,
      uv_rect,
      flip_v,
      layer_f,
      tint,
      lighting.color_scale,
      lighting.alpha_scale,
    )
    if is_double_sided {
      emit_reversed_face(
        arrays,
        a,
        b,
        c,
        d,
        face.normal,
        uv_rect,
        flip_v,
        layer_f,
        tint,
        lighting.color_scale,
        lighting.alpha_scale,
      )
    }
  }
}

///|
/// Push the per-vertex colors of one block's faces into `target`.
fn emit_face_colors(
  chunk : PaddedChunk,
  target : Array[Float],
  render_block : @block.RenderBlock,
  x : Int,
  y : Int,
  z : Int,
) -> Unit {
  let model = render_block.block.model
  let render_info = @shape.FaceSource::{
    faces: render_block.faces,
    state: render_block.block.state,
  }
  let tint = render_block.block.tint
  let push_color_alpha = (count : Int, color_scale : Float, alpha_scale : Float) => {
    push_face_color_into(target, count, color_scale, tint, alpha_scale)
  }
  let push_color = (count : Int, color_scale : Float) => {
    push_color_alpha(count, color_scale, 1.0F)
  }
  if (model.emit_colors)(render_info, push_color) {
    return
  }
  let is_double_sided = (model.double_sided)(render_info)
  for face in @shape.faces {
    guard face_lighting(chunk, model, render_info, face, render_block, x, y, z)
      is Some(lighting) else {
      continue
    }
    let count = if is_double_sided { 12 } else { 6 }
    push_face_color_into(
      target,
      count,
      lighting.color_scale,
      tint,
      lighting.alpha_scale,
    )
  }
}

///|
fn push_face_color_into(
  target : Array[Float],
  count : Int,
  color_scale : Float,
  tint : (Float, Float, Float, Float),
  alpha_scale : Float,
) -> Unit {
  let (tr, tg, tb, ta) = tint
  for _ in 0..<count {
    target.push(color_scale * tr)
    target.push(color_scale * tg)
    target.push(color_scale * tb)
    target.push(ta * alpha_scale)
  }
}
