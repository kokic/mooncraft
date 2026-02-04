///|
pub(all) struct ChunkEntry {
  x : Int
  y : Int
  z : Int
  data : Array[UInt]
  light : Bytes
}

///|
pub struct MeshData {
  positions : Array[Float]
  uvs : Array[Float]
  layers : Array[Float]
  colors : Array[Float]
  normals : Array[Float]
  count : Int
}

///|
pub struct MeshSplit {
  normal : MeshData
  leaf : MeshData
}

///|
fn box_face_corners(
  face : @shape.FaceName,
  min : (Float, Float, Float),
  max : (Float, Float, Float),
) -> ((Float, Float, Float), (Float, Float, Float), (Float, Float, Float), (Float, Float, Float)) {
  let (x0, y0, z0) = min
  let (x1, y1, z1) = max
  match face {
    @shape.FaceName::PosX =>
      ((x1, y0, z0), (x1, y0, z1), (x1, y1, z1), (x1, y1, z0))
    @shape.FaceName::NegX =>
      ((x0, y0, z1), (x0, y0, z0), (x0, y1, z0), (x0, y1, z1))
    @shape.FaceName::PosY =>
      ((x0, y1, z1), (x0, y1, z0), (x1, y1, z0), (x1, y1, z1))
    @shape.FaceName::NegY =>
      ((x0, y0, z0), (x0, y0, z1), (x1, y0, z1), (x1, y0, z0))
    @shape.FaceName::PosZ =>
      ((x1, y0, z1), (x0, y0, z1), (x0, y1, z1), (x1, y1, z1))
    @shape.FaceName::NegZ =>
      ((x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0))
  }
}

///|
fn face_corners_world(
  face : @shape.FaceGeom,
  x : Int,
  y : Int,
  z : Int,
  custom_box : ((Float, Float, Float), (Float, Float, Float))?,
) -> ((Float, Float, Float), (Float, Float, Float), (Float, Float, Float), (Float, Float, Float)) {
  match custom_box {
    Some((min, max)) => {
      let (a, b, c, d) = box_face_corners(face.name, min, max)
      let (ax, ay, az) = a
      let (bx, by, bz) = b
      let (cx, cy, cz) = c
      let (dx, dy, dz) = d
      let ox = Float::from_int(x)
      let oy = Float::from_int(y)
      let oz = Float::from_int(z)
      (
        (ax + ox, ay + oy, az + oz),
        (bx + ox, by + oy, bz + oz),
        (cx + ox, cy + oy, cz + oz),
        (dx + ox, dy + oy, dz + oz),
      )
    }
    None => {
      let a = face.corners[0]
      let b = face.corners[1]
      let c = face.corners[2]
      let d = face.corners[3]
      let (ax, ay, az) = a
      let (bx, by, bz) = b
      let (cx, cy, cz) = c
      let (dx, dy, dz) = d
      (
        (
          Float::from_int(ax + x),
          Float::from_int(ay + y),
          Float::from_int(az + z),
        ),
        (
          Float::from_int(bx + x),
          Float::from_int(by + y),
          Float::from_int(bz + z),
        ),
        (
          Float::from_int(cx + x),
          Float::from_int(cy + y),
          Float::from_int(cz + z),
        ),
        (
          Float::from_int(dx + x),
          Float::from_int(dy + y),
          Float::from_int(dz + z),
        ),
      )
    }
  }
}

///|

///|
pub fn build_chunk_mesh(
  registry : BlockRegistry,
  chunk_data : Array[UInt],
  chunk_light : Bytes,
  size : Int,
) -> MeshData {
  let positions : Array[Float] = []
  let uvs : Array[Float] = []
  let layers : Array[Float] = []
  let colors : Array[Float] = []
  let normals : Array[Float] = []
  let base_uvs : Array[(Float, Float)] = [
    (0, 0),
    (1, 0),
    (1, 1),
    (0, 0),
    (1, 1),
    (0, 1),
  ]
  let base_uvs_rot90 : Array[(Float, Float)] = base_uvs.map(fn(uv) {
    let (u, v) = uv
    (v, 1.0F - u)
  })
  let air_block = match registry.get_by_name("air") {
    Some(block) => block
    None =>
      return MeshData::{
        positions: [],
        uvs: [],
        layers: [],
        colors: [],
        normals: [],
        count: 0,
      }
  }
  let get_index = fn(x : Int, y : Int, z : Int) -> Int {
    (y * size + z) * size + x
  }
  let get_block = fn(x : Int, y : Int, z : Int) -> RenderBlock {
    if x < 0 || x >= size || y < 0 || y >= size || z < 0 || z >= size {
      air_block
    } else {
      let idx = get_index(x, y, z)
      match registry.get_by_long_id(chunk_data[idx]) {
        Some(block) => block
        None => air_block
      }
    }
  }
  let _ = chunk_light
  let push_face = fn(
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
    let (nx, ny, nz) = normal
    let (u0, v0, u1, v1) = uv_rect
    let verts : Array[(Float, Float, Float)] = [a, b, c, a, c, d]
    for i in 0..<6 {
      let (vx, vy, vz) = verts[i]
      positions.push(vx)
      positions.push(vy)
      positions.push(vz)
      colors.push(color_scale)
      colors.push(color_scale)
      colors.push(color_scale)
      colors.push(1.0F)
      normals.push(Float::from_int(nx))
      normals.push(Float::from_int(ny))
      normals.push(Float::from_int(nz))
      let (bu, bv) = base_uvs[i]
      let v = if flip_v { 1.0F - bv } else { bv }
      let u = u0 + bu * (u1 - u0)
      let v2 = v0 + v * (v1 - v0)
      uvs.push(u)
      uvs.push(v2)
      layers.push(layer_f)
    }
  }
  let push_face_rev = fn(
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
    let (nx, ny, nz) = normal
    let (u0, v0, u1, v1) = uv_rect
    let verts : Array[(Float, Float, Float)] = [a, c, b, a, d, c]
    let base_uvs_rev : Array[(Float, Float)] = [
      (0, 0),
      (1, 1),
      (1, 0),
      (0, 0),
      (0, 1),
      (1, 1),
    ]
    for i in 0..<6 {
      let (vx, vy, vz) = verts[i]
      positions.push(vx)
      positions.push(vy)
      positions.push(vz)
      colors.push(color_scale)
      colors.push(color_scale)
      colors.push(color_scale)
      colors.push(1.0F)
      normals.push(Float::from_int(nx))
      normals.push(Float::from_int(ny))
      normals.push(Float::from_int(nz))
      let (bu, bv) = base_uvs_rev[i]
      let v = if flip_v { 1.0F - bv } else { bv }
      let u = u0 + bu * (u1 - u0)
      let v2 = v0 + v * (v1 - v0)
      uvs.push(u)
      uvs.push(v2)
      layers.push(layer_f)
    }
  }
  let push_face_cube = fn(
    rotate_uv : Bool,
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
    let (nx, ny, nz) = normal
    let (u0, v0, u1, v1) = uv_rect
    let verts : Array[(Float, Float, Float)] = [a, b, c, a, c, d]
    let uvs_base = if rotate_uv { base_uvs_rot90 } else { base_uvs }
    for i in 0..<6 {
      let (vx, vy, vz) = verts[i]
      positions.push(vx)
      positions.push(vy)
      positions.push(vz)
      colors.push(color_scale)
      colors.push(color_scale)
      colors.push(color_scale)
      colors.push(1.0F)
      normals.push(Float::from_int(nx))
      normals.push(Float::from_int(ny))
      normals.push(Float::from_int(nz))
      let (bu, bv) = uvs_base[i]
      let v = if flip_v { 1.0F - bv } else { bv }
      let u = u0 + bu * (u1 - u0)
      let v2 = v0 + v * (v1 - v0)
      uvs.push(u)
      uvs.push(v2)
      layers.push(layer_f)
    }
  }
  for x in 0..<size {
    for y in 0..<size {
      for z in 0..<size {
        let block = get_block(x, y, z)
        if block.block.shape is Shape::Air {
          continue
        }
        match block.block.shape {
          Shape::Torch => {
            let bx = Float::from_int(x)
            let by = Float::from_int(y)
            let bz = Float::from_int(z)
            let layer_f = Float::from_int(block.faces.pos_x)
            @genus.Torch::append_mesh(
              block.block.state,
              layer_f,
              bx,
              by,
              bz,
              push_face,
            )
          }
          Shape::RedstoneTorch => {
            let bx = Float::from_int(x)
            let by = Float::from_int(y)
            let bz = Float::from_int(z)
            let layer_f = Float::from_int(block.faces.pos_x)
            @genus.Torch::append_redstone_mesh(
              block.block.state,
              layer_f,
              bx,
              by,
              bz,
              push_face,
            )
          }
          Shape::RedstoneTorchClassic => {
            let bx = Float::from_int(x)
            let by = Float::from_int(y)
            let bz = Float::from_int(z)
            let layer_f = Float::from_int(block.faces.pos_x)
            @genus.Torch::append_classic_mesh(
              block.block.state,
              layer_f,
              bx,
              by,
              bz,
              push_face_rev,
              push_face,
            )
          }
          _ => {
            let model = block.block.shape.model()
            let render_info = @shape.RenderInfo::{
              faces: block.faces,
              state: block.block.state,
            }
            let is_double_sided = (model.double_sided)(render_info)
            for face in @shape.faces {
              let (nx, ny, nz) = face.normal
              let neighbor = get_block(x + nx, y + ny, z + nz)
              if !neighbor.block.opacity.enable_occlusion_culling() {
                let shade = @util.face_shade_scale(nx, ny, nz)
                let color_scale = shade
                let layer = (model.face_layer)(render_info, face.name)
                let layer_f = Float::from_int(layer)
                let flip_uv = match face.name {
                  @shape.FaceName::PosX
                  | @shape.FaceName::NegX
                  | @shape.FaceName::PosZ
                  | @shape.FaceName::NegZ => true
                  _ => false
                }
                let custom_box = (model.face_box)(render_info, face.name)
                let (a, b, c, d) = face_corners_world(face, x, y, z, custom_box)
                let rotate_uv = (model.rotate_uv)(render_info, face)
                let uv_rect = (model.uv_rect)(render_info, face.name)
                push_face_cube(
                  rotate_uv,
                  a,
                  b,
                  c,
                  d,
                  face.normal,
                  layer_f,
                  uv_rect,
                  flip_uv,
                  color_scale,
                )
                if is_double_sided {
                  push_face_rev(
                    a,
                    b,
                    c,
                    d,
                    face.normal,
                    layer_f,
                    uv_rect,
                    flip_uv,
                    color_scale,
                  )
                }
              }
            }
          }
        }
      }
    }
  }
  MeshData::{
    positions,
    uvs,
    layers,
    colors,
    normals,
    count: positions.length() / 3,
  }
}

///|
pub fn build_chunk_mesh_split(
  registry : BlockRegistry,
  chunk_data : Array[UInt],
  chunk_light : Bytes,
  size : Int,
) -> MeshSplit {
  let positions : Array[Float] = []
  let uvs : Array[Float] = []
  let layers : Array[Float] = []
  let colors : Array[Float] = []
  let normals : Array[Float] = []
  let leaf_positions : Array[Float] = []
  let leaf_uvs : Array[Float] = []
  let leaf_layers : Array[Float] = []
  let leaf_colors : Array[Float] = []
  let leaf_normals : Array[Float] = []
  let base_uvs : Array[(Float, Float)] = [
    (0, 0),
    (1, 0),
    (1, 1),
    (0, 0),
    (1, 1),
    (0, 1),
  ]
  let base_uvs_rot90 : Array[(Float, Float)] = base_uvs.map(fn(uv) {
    let (u, v) = uv
    (v, 1.0F - u)
  })
  let air_block = match registry.get_by_name("air") {
    Some(block) => block
    None =>
      return MeshSplit::{
        normal: MeshData::{
          positions: [],
          uvs: [],
          layers: [],
          colors: [],
          normals: [],
          count: 0,
        },
        leaf: MeshData::{
          positions: [],
          uvs: [],
          layers: [],
          colors: [],
          normals: [],
          count: 0,
        },
      }
  }
  let get_index = fn(x : Int, y : Int, z : Int) -> Int {
    (y * size + z) * size + x
  }
  let get_block = fn(x : Int, y : Int, z : Int) -> RenderBlock {
    if x < 0 || x >= size || y < 0 || y >= size || z < 0 || z >= size {
      air_block
    } else {
      let idx = get_index(x, y, z)
      match registry.get_by_long_id(chunk_data[idx]) {
        Some(block) => block
        None => air_block
      }
    }
  }
  let _ = chunk_light
  let push_face_into = fn(
    positions : Array[Float],
    uvs : Array[Float],
    layers : Array[Float],
    colors : Array[Float],
    normals : Array[Float],
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
    let (nx, ny, nz) = normal
    let (u0, v0, u1, v1) = uv_rect
    let verts : Array[(Float, Float, Float)] = [a, b, c, a, c, d]
    for i in 0..<6 {
      let (vx, vy, vz) = verts[i]
      positions.push(vx)
      positions.push(vy)
      positions.push(vz)
      colors.push(color_scale)
      colors.push(color_scale)
      colors.push(color_scale)
      colors.push(1.0F)
      normals.push(Float::from_int(nx))
      normals.push(Float::from_int(ny))
      normals.push(Float::from_int(nz))
      let (bu, bv) = base_uvs[i]
      let v = if flip_v { 1.0F - bv } else { bv }
      let u = u0 + bu * (u1 - u0)
      let v2 = v0 + v * (v1 - v0)
      uvs.push(u)
      uvs.push(v2)
      layers.push(layer_f)
    }
  }
  let push_face_rev_into = fn(
    positions : Array[Float],
    uvs : Array[Float],
    layers : Array[Float],
    colors : Array[Float],
    normals : Array[Float],
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
    let (nx, ny, nz) = normal
    let (u0, v0, u1, v1) = uv_rect
    let verts : Array[(Float, Float, Float)] = [a, c, b, a, d, c]
    let base_uvs_rev : Array[(Float, Float)] = [
      (0, 0),
      (1, 1),
      (1, 0),
      (0, 0),
      (0, 1),
      (1, 1),
    ]
    for i in 0..<6 {
      let (vx, vy, vz) = verts[i]
      positions.push(vx)
      positions.push(vy)
      positions.push(vz)
      colors.push(color_scale)
      colors.push(color_scale)
      colors.push(color_scale)
      colors.push(1.0F)
      normals.push(Float::from_int(nx))
      normals.push(Float::from_int(ny))
      normals.push(Float::from_int(nz))
      let (bu, bv) = base_uvs_rev[i]
      let v = if flip_v { 1.0F - bv } else { bv }
      let u = u0 + bu * (u1 - u0)
      let v2 = v0 + v * (v1 - v0)
      uvs.push(u)
      uvs.push(v2)
      layers.push(layer_f)
    }
  }
  let push_face = fn(
    block : RenderBlock,
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
    if block.block.material is Material::TintedLeaf {
      push_face_into(
        leaf_positions, leaf_uvs, leaf_layers, leaf_colors, leaf_normals, a, b, c,
        d, normal, layer_f, uv_rect, flip_v, color_scale,
      )
    } else {
      push_face_into(
        positions, uvs, layers, colors, normals, a, b, c, d, normal, layer_f, uv_rect,
        flip_v, color_scale,
      )
    }
  }
  let push_face_rev = fn(
    block : RenderBlock,
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
    if block.block.material is Material::TintedLeaf {
      push_face_rev_into(
        leaf_positions, leaf_uvs, leaf_layers, leaf_colors, leaf_normals, a, b, c,
        d, normal, layer_f, uv_rect, flip_v, color_scale,
      )
    } else {
      push_face_rev_into(
        positions, uvs, layers, colors, normals, a, b, c, d, normal, layer_f, uv_rect,
        flip_v, color_scale,
      )
    }
  }
  let push_face_cube = fn(
    block : RenderBlock,
    rotate_uv : Bool,
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
    let (nx, ny, nz) = normal
    let (u0, v0, u1, v1) = uv_rect
    let verts : Array[(Float, Float, Float)] = [a, b, c, a, c, d]
    let uvs_base = if rotate_uv { base_uvs_rot90 } else { base_uvs }
    let (positions_ref, uvs_ref, layers_ref, colors_ref, normals_ref) = if block.block.material
      is Material::TintedLeaf {
      (leaf_positions, leaf_uvs, leaf_layers, leaf_colors, leaf_normals)
    } else {
      (positions, uvs, layers, colors, normals)
    }
    for i in 0..<6 {
      let (vx, vy, vz) = verts[i]
      positions_ref.push(vx)
      positions_ref.push(vy)
      positions_ref.push(vz)
      colors_ref.push(color_scale)
      colors_ref.push(color_scale)
      colors_ref.push(color_scale)
      colors_ref.push(1.0F)
      normals_ref.push(Float::from_int(nx))
      normals_ref.push(Float::from_int(ny))
      normals_ref.push(Float::from_int(nz))
      let (bu, bv) = uvs_base[i]
      let v = if flip_v { 1.0F - bv } else { bv }
      let u = u0 + bu * (u1 - u0)
      let v2 = v0 + v * (v1 - v0)
      uvs_ref.push(u)
      uvs_ref.push(v2)
      layers_ref.push(layer_f)
    }
  }
  for x in 0..<size {
    for y in 0..<size {
      for z in 0..<size {
        let block = get_block(x, y, z)
        if block.block.shape is Shape::Air {
          continue
        }
        match block.block.shape {
          Shape::Torch => {
            let bx = Float::from_int(x)
            let by = Float::from_int(y)
            let bz = Float::from_int(z)
            let layer_f = Float::from_int(block.faces.pos_x)
            @genus.Torch::append_mesh(block.block.state, layer_f, bx, by, bz, fn(
              a,
              b,
              c,
              d,
              normal,
              layer_f,
              uv_rect,
              flip_v,
              color_scale,
            ) {
              push_face(
                block, a, b, c, d, normal, layer_f, uv_rect, flip_v, color_scale,
              )
            })
          }
          Shape::RedstoneTorch => {
            let bx = Float::from_int(x)
            let by = Float::from_int(y)
            let bz = Float::from_int(z)
            let layer_f = Float::from_int(block.faces.pos_x)
            @genus.Torch::append_redstone_mesh(
              block.block.state,
              layer_f,
              bx,
              by,
              bz,
              fn(a, b, c, d, normal, layer_f, uv_rect, flip_v, color_scale) {
                push_face(
                  block, a, b, c, d, normal, layer_f, uv_rect, flip_v, color_scale,
                )
              },
            )
          }
          Shape::RedstoneTorchClassic => {
            let bx = Float::from_int(x)
            let by = Float::from_int(y)
            let bz = Float::from_int(z)
            let layer_f = Float::from_int(block.faces.pos_x)
            @genus.Torch::append_classic_mesh(
              block.block.state,
              layer_f,
              bx,
              by,
              bz,
              fn(a, b, c, d, normal, layer_f, uv_rect, flip_v, color_scale) {
                push_face_rev(
                  block, a, b, c, d, normal, layer_f, uv_rect, flip_v, color_scale,
                )
              },
              fn(a, b, c, d, normal, layer_f, uv_rect, flip_v, color_scale) {
                push_face(
                  block, a, b, c, d, normal, layer_f, uv_rect, flip_v, color_scale,
                )
              },
            )
          }
          _ => {
            let model = block.block.shape.model()
            let render_info = @shape.RenderInfo::{
              faces: block.faces,
              state: block.block.state,
            }
            let is_double_sided = (model.double_sided)(render_info)
            for face in @shape.faces {
              let (nx, ny, nz) = face.normal
              let neighbor = get_block(x + nx, y + ny, z + nz)
              if !neighbor.block.opacity.enable_occlusion_culling() {
                let shade = @util.face_shade_scale(nx, ny, nz)
                let color_scale = shade
                let layer = (model.face_layer)(render_info, face.name)
                let layer_f = Float::from_int(layer)
                let flip_uv = match face.name {
                  @shape.FaceName::PosX
                  | @shape.FaceName::NegX
                  | @shape.FaceName::PosZ
                  | @shape.FaceName::NegZ => true
                  _ => false
                }
                let custom_box = (model.face_box)(render_info, face.name)
                let (a, b, c, d) = face_corners_world(face, x, y, z, custom_box)
                let rotate_uv = (model.rotate_uv)(render_info, face)
                let uv_rect = (model.uv_rect)(render_info, face.name)
                push_face_cube(
                  block,
                  rotate_uv,
                  a,
                  b,
                  c,
                  d,
                  face.normal,
                  layer_f,
                  uv_rect,
                  flip_uv,
                  color_scale,
                )
                if is_double_sided {
                  push_face_rev(
                    block,
                    a,
                    b,
                    c,
                    d,
                    face.normal,
                    layer_f,
                    uv_rect,
                    flip_uv,
                    color_scale,
                  )
                }
              }
            }
          }
        }
      }
    }
  }
  MeshSplit::{
    normal: MeshData::{
      positions,
      uvs,
      layers,
      colors,
      normals,
      count: positions.length() / 3,
    },
    leaf: MeshData::{
      positions: leaf_positions,
      uvs: leaf_uvs,
      layers: leaf_layers,
      colors: leaf_colors,
      normals: leaf_normals,
      count: leaf_positions.length() / 3,
    },
  }
}

///|
/// Build only per-vertex colors for a chunk mesh (same vertex order as build_chunk_mesh).
pub fn build_chunk_colors(
  registry : BlockRegistry,
  chunk_data : Array[UInt],
  chunk_light : Bytes,
  size : Int,
) -> Array[Float] {
  let colors : Array[Float] = []
  let _ = chunk_light
  let push_color = fn(count : Int, color_scale : Float) -> Unit {
    for _ in 0..<count {
      colors.push(color_scale)
      colors.push(color_scale)
      colors.push(color_scale)
      colors.push(1.0F)
    }
  }
  let air_block = match registry.get_by_name("air") {
    Some(block) => block
    None => return []
  }
  let get_index = fn(x : Int, y : Int, z : Int) -> Int {
    (y * size + z) * size + x
  }
  let get_block = fn(x : Int, y : Int, z : Int) -> RenderBlock {
    if x < 0 || x >= size || y < 0 || y >= size || z < 0 || z >= size {
      air_block
    } else {
      let idx = get_index(x, y, z)
      match registry.get_by_long_id(chunk_data[idx]) {
        Some(block) => block
        None => air_block
      }
    }
  }
  for x in 0..<size {
    for y in 0..<size {
      for z in 0..<size {
        let block = get_block(x, y, z)
        if block.block.shape is Shape::Air {
          continue
        }
        match block.block.shape {
          Shape::Torch => @genus.Torch::append_colors(push_color)
          Shape::RedstoneTorch =>
            @genus.Torch::append_redstone_colors(push_color)
          Shape::RedstoneTorchClassic =>
            @genus.Torch::append_classic_colors(push_color)
          _ =>
            for face in @shape.faces {
              let (nx, ny, nz) = face.normal
              let neighbor = get_block(x + nx, y + ny, z + nz)
              if neighbor.block.shape is Shape::Air ||
                neighbor.block.shape is Shape::Torch ||
                neighbor.block.shape is Shape::RedstoneTorch ||
                neighbor.block.shape is Shape::RedstoneTorchClassic {
                let shade = @util.face_shade_scale(nx, ny, nz)
                let color_scale = shade
                push_color(6, color_scale)
              }
            }
        }
      }
    }
  }
  colors
}

///|
pub fn build_world_mesh(
  registry : BlockRegistry,
  entries : Array[ChunkEntry],
  size : Int,
) -> MeshData {
  let positions : Array[Float] = []
  let uvs : Array[Float] = []
  let layers : Array[Float] = []
  let colors : Array[Float] = []
  let normals : Array[Float] = []
  for entry in entries {
    let mesh = build_chunk_mesh(registry, entry.data, entry.light, size)
    let offset_x = Float::from_int(entry.x * size)
    let offset_y = Float::from_int(entry.y * size)
    let offset_z = Float::from_int(entry.z * size)
    for i in 0..<mesh.count {
      let pidx = i * 3
      positions.push(mesh.positions[pidx] + offset_x)
      positions.push(mesh.positions[pidx + 1] + offset_y)
      positions.push(mesh.positions[pidx + 2] + offset_z)
      let uidx = i * 2
      uvs.push(mesh.uvs[uidx])
      uvs.push(mesh.uvs[uidx + 1])
      layers.push(mesh.layers[i])
      let cidx = i * 4
      colors.push(mesh.colors[cidx])
      colors.push(mesh.colors[cidx + 1])
      colors.push(mesh.colors[cidx + 2])
      colors.push(mesh.colors[cidx + 3])
      let nidx = i * 3
      normals.push(mesh.normals[nidx])
      normals.push(mesh.normals[nidx + 1])
      normals.push(mesh.normals[nidx + 2])
    }
  }
  MeshData::{
    positions,
    uvs,
    layers,
    colors,
    normals,
    count: positions.length() / 3,
  }
}

///|
pub fn build_world_mesh_split(
  registry : BlockRegistry,
  entries : Array[ChunkEntry],
  size : Int,
) -> MeshSplit {
  let positions : Array[Float] = []
  let uvs : Array[Float] = []
  let layers : Array[Float] = []
  let colors : Array[Float] = []
  let normals : Array[Float] = []
  let leaf_positions : Array[Float] = []
  let leaf_uvs : Array[Float] = []
  let leaf_layers : Array[Float] = []
  let leaf_colors : Array[Float] = []
  let leaf_normals : Array[Float] = []
  for entry in entries {
    let mesh = build_chunk_mesh_split(registry, entry.data, entry.light, size)
    let offset_x = Float::from_int(entry.x * size)
    let offset_y = Float::from_int(entry.y * size)
    let offset_z = Float::from_int(entry.z * size)
    let normal = mesh.normal
    for i in 0..<normal.count {
      let pidx = i * 3
      positions.push(normal.positions[pidx] + offset_x)
      positions.push(normal.positions[pidx + 1] + offset_y)
      positions.push(normal.positions[pidx + 2] + offset_z)
      let uidx = i * 2
      uvs.push(normal.uvs[uidx])
      uvs.push(normal.uvs[uidx + 1])
      layers.push(normal.layers[i])
      let cidx = i * 4
      colors.push(normal.colors[cidx])
      colors.push(normal.colors[cidx + 1])
      colors.push(normal.colors[cidx + 2])
      colors.push(normal.colors[cidx + 3])
      let nidx = i * 3
      normals.push(normal.normals[nidx])
      normals.push(normal.normals[nidx + 1])
      normals.push(normal.normals[nidx + 2])
    }
    let leaf = mesh.leaf
    for i in 0..<leaf.count {
      let pidx = i * 3
      leaf_positions.push(leaf.positions[pidx] + offset_x)
      leaf_positions.push(leaf.positions[pidx + 1] + offset_y)
      leaf_positions.push(leaf.positions[pidx + 2] + offset_z)
      let uidx = i * 2
      leaf_uvs.push(leaf.uvs[uidx])
      leaf_uvs.push(leaf.uvs[uidx + 1])
      leaf_layers.push(leaf.layers[i])
      let cidx = i * 4
      leaf_colors.push(leaf.colors[cidx])
      leaf_colors.push(leaf.colors[cidx + 1])
      leaf_colors.push(leaf.colors[cidx + 2])
      leaf_colors.push(leaf.colors[cidx + 3])
      let nidx = i * 3
      leaf_normals.push(leaf.normals[nidx])
      leaf_normals.push(leaf.normals[nidx + 1])
      leaf_normals.push(leaf.normals[nidx + 2])
    }
  }
  MeshSplit::{
    normal: MeshData::{
      positions,
      uvs,
      layers,
      colors,
      normals,
      count: positions.length() / 3,
    },
    leaf: MeshData::{
      positions: leaf_positions,
      uvs: leaf_uvs,
      layers: leaf_layers,
      colors: leaf_colors,
      normals: leaf_normals,
      count: leaf_positions.length() / 3,
    },
  }
}
