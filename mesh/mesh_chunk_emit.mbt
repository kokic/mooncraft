///|
/// Padded chunk sampling: resolves block render data and light at any
/// coordinate, treating out-of-bounds voxels as air (light 15).
priv struct PaddedChunk {
  registry : @block.RenderRegistry
  data : Array[UInt]
  light : Bytes
  size : Int
  pad : Int
  base_len : Int
  pad_len : Int
  air_block : @block.RenderBlock
}

///|
fn PaddedChunk::new(
  registry : @block.RenderRegistry,
  data : Array[UInt],
  light : Bytes,
  size : Int,
) -> PaddedChunk? {
  guard registry.get_by_name(@schema.AIR_NAME) is Some(air_block) else { None }
  let pad = size + 2
  Some({
    registry,
    data,
    light,
    size,
    pad,
    base_len: size * size * size,
    pad_len: pad * pad * pad,
    air_block,
  })
}

///|
fn PaddedChunk::block(
  self : PaddedChunk,
  x : Int,
  y : Int,
  z : Int,
) -> @block.RenderBlock {
  let data_len = self.data.length()
  if data_len == self.base_len {
    if x < 0 ||
      x >= self.size ||
      y < 0 ||
      y >= self.size ||
      z < 0 ||
      z >= self.size {
      self.air_block
    } else {
      let idx = (y * self.size + z) * self.size + x
      self.registry.get_by_internal_id(self.data[idx]).unwrap_or(self.air_block)
    }
  } else if data_len == self.pad_len {
    let px = x + 1
    let py = y + 1
    let pz = z + 1
    if px < 0 ||
      px >= self.pad ||
      py < 0 ||
      py >= self.pad ||
      pz < 0 ||
      pz >= self.pad {
      self.air_block
    } else {
      let idx = (py * self.pad + pz) * self.pad + px
      self.registry.get_by_internal_id(self.data[idx]).unwrap_or(self.air_block)
    }
  } else {
    self.air_block
  }
}

///|
fn PaddedChunk::light(self : PaddedChunk, x : Int, y : Int, z : Int) -> Int {
  let light_len = self.light.length()
  if light_len == self.base_len {
    if x < 0 ||
      x >= self.size ||
      y < 0 ||
      y >= self.size ||
      z < 0 ||
      z >= self.size {
      15
    } else {
      let idx = (y * self.size + z) * self.size + x
      self.light[idx].to_int()
    }
  } else if light_len == self.pad_len {
    let px = x + 1
    let py = y + 1
    let pz = z + 1
    if px < 0 ||
      px >= self.pad ||
      py < 0 ||
      py >= self.pad ||
      pz < 0 ||
      pz >= self.pad {
      0
    } else {
      let idx = (py * self.pad + pz) * self.pad + px
      self.light[idx].to_int()
    }
  } else {
    15
  }
}

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
let face_uvs_rot90 : Array[(Float, Float)] = face_uvs_base.map(fn(uv) {
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
/// The four render buckets of a split chunk mesh, keyed by block kind.
priv struct MeshSplitTargets {
  normal : MeshFaceArrays
  leaf : MeshFaceArrays
  water : MeshFaceArrays
  translucent : MeshFaceArrays
}

///|
fn MeshSplitTargets::new() -> MeshSplitTargets {
  let empty = fn() -> MeshFaceArrays {
    { positions: [], uvs: [], layers: [], colors: [], normals: None }
  }
  { normal: empty(), leaf: empty(), water: empty(), translucent: empty() }
}

///|
fn MeshSplitTargets::for_block(
  self : MeshSplitTargets,
  render_block : @block.RenderBlock,
) -> MeshFaceArrays {
  if render_block.block.is_water() {
    self.water
  } else if render_block.block.material is @block.Material::TintedLeaf {
    self.leaf
  } else if render_block.block.alpha_mode is @block.AlphaMode::Translucent {
    self.translucent
  } else {
    self.normal
  }
}

///|
fn MeshSplitTargets::into_mesh_split(self : MeshSplitTargets) -> MeshSplit {
  let finish = fn(arrays : MeshFaceArrays) -> MeshData {
    MeshData::{
      positions: arrays.positions,
      uvs: arrays.uvs,
      layers: arrays.layers,
      colors: arrays.colors,
      normals: [],
      count: arrays.positions.length() / 3,
    }
  }
  MeshSplit::{
    normal: finish(self.normal),
    leaf: finish(self.leaf),
    water: finish(self.water),
    translucent: finish(self.translucent),
  }
}

///|
/// The four color buckets of a split chunk mesh.
priv struct ColorTargets {
  normal : Array[Float]
  leaf : Array[Float]
  water : Array[Float]
  translucent : Array[Float]
}

///|
fn ColorTargets::new() -> ColorTargets {
  { normal: [], leaf: [], water: [], translucent: [] }
}

///|
fn ColorTargets::for_block(
  self : ColorTargets,
  render_block : @block.RenderBlock,
) -> Array[Float] {
  if render_block.block.is_water() {
    self.water
  } else if render_block.block.material is @block.Material::TintedLeaf {
    self.leaf
  } else if render_block.block.alpha_mode is @block.AlphaMode::Translucent {
    self.translucent
  } else {
    self.normal
  }
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
fn emit_face_rev(
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
fn emit_face_rev_cube(
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
/// Whether a face is emitted and whether it is a transparent chunk-boundary
/// face: the model occlusion rules plus the boundary override.
fn face_emit_state(
  chunk : PaddedChunk,
  model : @shape.Model,
  render_info : @shape.FaceSource,
  face : @shape.FaceGeom,
  render_block : @block.RenderBlock,
  x : Int,
  y : Int,
  z : Int,
) -> (Bool, Bool) {
  let (nx, ny, nz) = face.normal
  let neighbor = chunk.block(x + nx, y + ny, z + nz)
  let visible = (model.face_visible)(render_info, face, @shape.FaceOcclusion::{
    neighbor_occludes: neighbor.block.occlusion_cull,
    same_block_cull: render_block.block.inter_cull &&
    render_block.internal_id == neighbor.internal_id,
  })
  let boundary_transparent = is_chunk_boundary_face(
      x,
      y,
      z,
      nx,
      ny,
      nz,
      chunk.size,
    ) &&
    !render_block.block.occlusion_cull
  (visible, boundary_transparent)
}

///|
/// Face shade combined with the neighbor light level.
fn face_color_scale(light : Int, nx : Int, ny : Int, nz : Int) -> Float {
  @util.face_shade_scale(nx, ny, nz) * @util.light_level_scale(light)
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
  let model = @block.model_by_block(render_block.block)
  let render_info = @shape.FaceSource::{
    faces: render_block.faces,
    state: render_block.block.state,
  }
  let bx = Float::from_int(x)
  let by = Float::from_int(y)
  let bz = Float::from_int(z)
  let tint = render_block.block.material.tint()
  let emit_face = fn(
    a : (Float, Float, Float),
    b : (Float, Float, Float),
    c : (Float, Float, Float),
    d : (Float, Float, Float),
    normal : (Int, Int, Int),
    layer_f : Float,
    uv_rect : (Float, Float, Float, Float),
    flip_v : Bool,
    color_scale : Float,
  ) -> Unit {
    emit_face(
      arrays, a, b, c, d, normal, uv_rect, flip_v, layer_f, tint, color_scale, 1.0F,
    )
  }
  let emit_face_rev = fn(
    a : (Float, Float, Float),
    b : (Float, Float, Float),
    c : (Float, Float, Float),
    d : (Float, Float, Float),
    normal : (Int, Int, Int),
    layer_f : Float,
    uv_rect : (Float, Float, Float, Float),
    flip_v : Bool,
    color_scale : Float,
  ) -> Unit {
    emit_face_rev(
      arrays, a, b, c, d, normal, uv_rect, flip_v, layer_f, tint, color_scale, 1.0F,
    )
  }
  if (model.emit_mesh)(render_info, bx, by, bz, emit_face, emit_face_rev) {
    return
  }
  let is_double_sided = (model.double_sided)(render_info)
  for face in @shape.faces {
    let (visible, boundary_transparent) = face_emit_state(
      chunk, model, render_info, face, render_block, x, y, z,
    )
    if visible || boundary_transparent {
      let (nx, ny, nz) = face.normal
      let light = chunk.light(x + nx, y + ny, z + nz)
      let color_scale = face_color_scale(light, nx, ny, nz)
      let alpha_scale = if boundary_transparent && !visible {
        0.0F
      } else {
        1.0F
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
        color_scale,
        alpha_scale,
      )
      if is_double_sided {
        emit_face_rev_cube(
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
          color_scale,
          alpha_scale,
        )
      }
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
  let model = @block.model_by_block(render_block.block)
  let render_info = @shape.FaceSource::{
    faces: render_block.faces,
    state: render_block.block.state,
  }
  let tint = render_block.block.material.tint()
  let push_color_alpha = fn(
    count : Int,
    color_scale : Float,
    alpha_scale : Float,
  ) -> Unit {
    push_face_color_into(target, count, color_scale, tint, alpha_scale)
  }
  let push_color = fn(count : Int, color_scale : Float) -> Unit {
    push_color_alpha(count, color_scale, 1.0F)
  }
  if (model.emit_colors)(render_info, push_color) {
    return
  }
  let is_double_sided = (model.double_sided)(render_info)
  for face in @shape.faces {
    let (visible, boundary_transparent) = face_emit_state(
      chunk, model, render_info, face, render_block, x, y, z,
    )
    if visible || boundary_transparent {
      let (nx, ny, nz) = face.normal
      let light = chunk.light(x + nx, y + ny, z + nz)
      let color_scale = face_color_scale(light, nx, ny, nz)
      let alpha_scale = if boundary_transparent && !visible {
        0.0F
      } else {
        1.0F
      }
      let count = if is_double_sided { 12 } else { 6 }
      push_face_color_into(target, count, color_scale, tint, alpha_scale)
    }
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
