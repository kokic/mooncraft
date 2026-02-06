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
  translucent : MeshData
}

///|
pub struct MeshColorsSplit {
  normal : Array[Float]
  leaf : Array[Float]
  translucent : Array[Float]
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
fn is_chunk_boundary_face(
  x : Int,
  y : Int,
  z : Int,
  nx : Int,
  ny : Int,
  nz : Int,
  size : Int,
) -> Bool {
  (nx == -1 && x == 0) ||
  (nx == 1 && x == size - 1) ||
  (ny == -1 && y == 0) ||
  (ny == 1 && y == size - 1) ||
  (nz == -1 && z == 0) ||
  (nz == 1 && z == size - 1)
}

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
  let mut tint_r = 1.0F
  let mut tint_g = 1.0F
  let mut tint_b = 1.0F
  let mut tint_a = 1.0F
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
  let data_len = chunk_data.length()
  let base_len = size * size * size
  let pad = size + 2
  let pad_len = pad * pad * pad
  let get_block = fn(x : Int, y : Int, z : Int) -> RenderBlock {
    if data_len == base_len {
      if x < 0 || x >= size || y < 0 || y >= size || z < 0 || z >= size {
        air_block
      } else {
        let idx = get_index(x, y, z)
        match registry.get_by_long_id(chunk_data[idx]) {
          Some(block) => block
          None => air_block
        }
      }
    } else if data_len == pad_len {
      let px = x + 1
      let py = y + 1
      let pz = z + 1
      if px < 0 || px >= pad || py < 0 || py >= pad || pz < 0 ||
        pz >= pad {
        air_block
      } else {
        let idx = (py * pad + pz) * pad + px
        match registry.get_by_long_id(chunk_data[idx]) {
          Some(block) => block
          None => air_block
        }
      }
    } else {
      air_block
    }
  }
  let light_len = chunk_light.length()
  let get_light = fn(x : Int, y : Int, z : Int) -> Int {
    if light_len == base_len {
      if x < 0 || x >= size || y < 0 || y >= size || z < 0 || z >= size {
        15
      } else {
        let idx = get_index(x, y, z)
        chunk_light[idx].to_int()
      }
    } else if light_len == pad_len {
      let px = x + 1
      let py = y + 1
      let pz = z + 1
      if px < 0 || px >= pad || py < 0 || py >= pad || pz < 0 ||
        pz >= pad {
        0
      } else {
        let idx = (py * pad + pz) * pad + px
        chunk_light[idx].to_int()
      }
    } else {
      15
    }
  }
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
      colors.push(color_scale * tint_r)
      colors.push(color_scale * tint_g)
      colors.push(color_scale * tint_b)
      colors.push(tint_a)
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
      colors.push(color_scale * tint_r)
      colors.push(color_scale * tint_g)
      colors.push(color_scale * tint_b)
      colors.push(tint_a)
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
    alpha_scale : Float,
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
      colors.push(color_scale * tint_r)
      colors.push(color_scale * tint_g)
      colors.push(color_scale * tint_b)
      colors.push(tint_a * alpha_scale)
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
  let push_face_rev_cube = fn(
    a : (Float, Float, Float),
    b : (Float, Float, Float),
    c : (Float, Float, Float),
    d : (Float, Float, Float),
    normal : (Int, Int, Int),
    layer_f : Float,
    uv_rect : (Float, Float, Float, Float),
    flip_v : Bool,
    color_scale : Float,
    alpha_scale : Float,
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
      colors.push(color_scale * tint_r)
      colors.push(color_scale * tint_g)
      colors.push(color_scale * tint_b)
      colors.push(tint_a * alpha_scale)
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
  for x in 0..<size {
    for y in 0..<size {
      for z in 0..<size {
        let block = get_block(x, y, z)
        if block.block.shape is Shape::Air {
          continue
        }
        let (tr, tg, tb, ta) = block.block.material.tint()
        tint_r = tr
        tint_g = tg
        tint_b = tb
        tint_a = ta
        let model = block.block.shape.model()
        let render_info = @shape.FaceSource::{
          faces: block.faces,
          state: block.block.state,
        }
        let bx = Float::from_int(x)
        let by = Float::from_int(y)
        let bz = Float::from_int(z)
        if (model.emit_mesh)(render_info, bx, by, bz, push_face, push_face_rev) {
          continue
        }
        let is_double_sided = (model.double_sided)(render_info)
        for face in @shape.faces {
          let (nx, ny, nz) = face.normal
          let neighbor = get_block(x + nx, y + ny, z + nz)
          let occlusion = @shape.FaceOcclusion::{
            neighbor_occludes: neighbor.block.occlusion_cull,
            same_block_cull: block.block.inter_cull && block.long_id == neighbor.long_id,
          }
          let visible = (model.face_visible)(render_info, face, occlusion)
          let boundary_transparent = is_chunk_boundary_face(
            x,
            y,
            z,
            nx,
            ny,
            nz,
            size,
          ) && !block.block.occlusion_cull
          if visible || boundary_transparent {
            let light = get_light(x + nx, y + ny, z + nz)
            let light_scale = @util.light_level_scale(light)
            let shade = @util.face_shade_scale(nx, ny, nz)
            let color_scale = shade * light_scale
            let alpha_scale = if boundary_transparent && !visible {
              0.0F
            } else {
              1.0F
            }
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
              alpha_scale,
            )
            if is_double_sided {
              push_face_rev_cube(
                a,
                b,
                c,
                d,
                face.normal,
                layer_f,
                uv_rect,
                flip_uv,
                color_scale,
                alpha_scale,
              )
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
  let trans_positions : Array[Float] = []
  let trans_uvs : Array[Float] = []
  let trans_layers : Array[Float] = []
  let trans_colors : Array[Float] = []
  let trans_normals : Array[Float] = []
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
        translucent: MeshData::{
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
  let data_len = chunk_data.length()
  let base_len = size * size * size
  let pad = size + 2
  let pad_len = pad * pad * pad
  let get_block = fn(x : Int, y : Int, z : Int) -> RenderBlock {
    if data_len == base_len {
      if x < 0 || x >= size || y < 0 || y >= size || z < 0 || z >= size {
        air_block
      } else {
        let idx = get_index(x, y, z)
        match registry.get_by_long_id(chunk_data[idx]) {
          Some(block) => block
          None => air_block
        }
      }
    } else if data_len == pad_len {
      let px = x + 1
      let py = y + 1
      let pz = z + 1
      if px < 0 || px >= pad || py < 0 || py >= pad || pz < 0 ||
        pz >= pad {
        air_block
      } else {
        let idx = (py * pad + pz) * pad + px
        match registry.get_by_long_id(chunk_data[idx]) {
          Some(block) => block
          None => air_block
        }
      }
    } else {
      air_block
    }
  }
  let light_len = chunk_light.length()
  let get_light = fn(x : Int, y : Int, z : Int) -> Int {
    if light_len == base_len {
      if x < 0 || x >= size || y < 0 || y >= size || z < 0 || z >= size {
        15
      } else {
        let idx = get_index(x, y, z)
        chunk_light[idx].to_int()
      }
    } else if light_len == pad_len {
      let px = x + 1
      let py = y + 1
      let pz = z + 1
      if px < 0 || px >= pad || py < 0 || py >= pad || pz < 0 ||
        pz >= pad {
        0
      } else {
        let idx = (py * pad + pz) * pad + px
        chunk_light[idx].to_int()
      }
    } else {
      15
    }
  }
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
    tint : (Float, Float, Float, Float),
    alpha_scale : Float,
  ) -> Unit {
    let (nx, ny, nz) = normal
    let (u0, v0, u1, v1) = uv_rect
    let verts : Array[(Float, Float, Float)] = [a, b, c, a, c, d]
    let (tr, tg, tb, ta) = tint
    for i in 0..<6 {
      let (vx, vy, vz) = verts[i]
      positions.push(vx)
      positions.push(vy)
      positions.push(vz)
      colors.push(color_scale * tr)
      colors.push(color_scale * tg)
      colors.push(color_scale * tb)
      colors.push(ta * alpha_scale)
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
    tint : (Float, Float, Float, Float),
    alpha_scale : Float,
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
    let (tr, tg, tb, ta) = tint
    for i in 0..<6 {
      let (vx, vy, vz) = verts[i]
      positions.push(vx)
      positions.push(vy)
      positions.push(vz)
      colors.push(color_scale * tr)
      colors.push(color_scale * tg)
      colors.push(color_scale * tb)
      colors.push(ta * alpha_scale)
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
  let select_arrays = fn(
    block : RenderBlock,
  ) -> (Array[Float], Array[Float], Array[Float], Array[Float], Array[Float]) {
    if block.block.material is Material::TintedLeaf {
      (leaf_positions, leaf_uvs, leaf_layers, leaf_colors, leaf_normals)
    } else if block.block.alpha_mode is AlphaMode::Translucent {
      (trans_positions, trans_uvs, trans_layers, trans_colors, trans_normals)
    } else {
      (positions, uvs, layers, colors, normals)
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
    let tint = block.block.material.tint()
    let (positions_ref, uvs_ref, layers_ref, colors_ref, normals_ref) = select_arrays(block)
    push_face_into(
      positions_ref,
      uvs_ref,
      layers_ref,
      colors_ref,
      normals_ref,
      a,
      b,
      c,
      d,
      normal,
      layer_f,
      uv_rect,
      flip_v,
      color_scale,
      tint,
      1.0F,
    )
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
    let tint = block.block.material.tint()
    let (positions_ref, uvs_ref, layers_ref, colors_ref, normals_ref) = select_arrays(block)
    push_face_rev_into(
      positions_ref,
      uvs_ref,
      layers_ref,
      colors_ref,
      normals_ref,
      a,
      b,
      c,
      d,
      normal,
      layer_f,
      uv_rect,
      flip_v,
      color_scale,
      tint,
      1.0F,
    )
  }
  let push_face_rev_cube = fn(
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
    alpha_scale : Float,
  ) -> Unit {
    let tint = block.block.material.tint()
    let (positions_ref, uvs_ref, layers_ref, colors_ref, normals_ref) = select_arrays(block)
    push_face_rev_into(
      positions_ref,
      uvs_ref,
      layers_ref,
      colors_ref,
      normals_ref,
      a,
      b,
      c,
      d,
      normal,
      layer_f,
      uv_rect,
      flip_v,
      color_scale,
      tint,
      alpha_scale,
    )
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
    alpha_scale : Float,
  ) -> Unit {
    let (nx, ny, nz) = normal
    let (u0, v0, u1, v1) = uv_rect
    let verts : Array[(Float, Float, Float)] = [a, b, c, a, c, d]
    let uvs_base = if rotate_uv { base_uvs_rot90 } else { base_uvs }
    let (positions_ref, uvs_ref, layers_ref, colors_ref, normals_ref) = select_arrays(block)
    let (tr, tg, tb, ta) = block.block.material.tint()
    for i in 0..<6 {
      let (vx, vy, vz) = verts[i]
      positions_ref.push(vx)
      positions_ref.push(vy)
      positions_ref.push(vz)
      colors_ref.push(color_scale * tr)
      colors_ref.push(color_scale * tg)
      colors_ref.push(color_scale * tb)
      colors_ref.push(ta * alpha_scale)
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
        let model = block.block.shape.model()
        let render_info = @shape.FaceSource::{
          faces: block.faces,
          state: block.block.state,
        }
        let bx = Float::from_int(x)
        let by = Float::from_int(y)
        let bz = Float::from_int(z)
        let emit_face = fn(
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
        }
        let emit_face_rev = fn(
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
          push_face_rev(
            block, a, b, c, d, normal, layer_f, uv_rect, flip_v, color_scale,
          )
        }
        if (model.emit_mesh)(render_info, bx, by, bz, emit_face, emit_face_rev) {
          continue
        }
        let is_double_sided = (model.double_sided)(render_info)
        for face in @shape.faces {
          let (nx, ny, nz) = face.normal
          let neighbor = get_block(x + nx, y + ny, z + nz)
          let occlusion = @shape.FaceOcclusion::{
            neighbor_occludes: neighbor.block.occlusion_cull,
            same_block_cull: block.block.inter_cull && block.long_id == neighbor.long_id,
          }
          let visible = (model.face_visible)(render_info, face, occlusion)
          let boundary_transparent = is_chunk_boundary_face(
            x,
            y,
            z,
            nx,
            ny,
            nz,
            size,
          ) && !block.block.occlusion_cull
          if visible || boundary_transparent {
            let light = get_light(x + nx, y + ny, z + nz)
            let light_scale = @util.light_level_scale(light)
            let shade = @util.face_shade_scale(nx, ny, nz)
            let color_scale = shade * light_scale
            let alpha_scale = if boundary_transparent && !visible {
              0.0F
            } else {
              1.0F
            }
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
              alpha_scale,
            )
            if is_double_sided {
              push_face_rev_cube(
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
                alpha_scale,
              )
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
    translucent: MeshData::{
      positions: trans_positions,
      uvs: trans_uvs,
      layers: trans_layers,
      colors: trans_colors,
      normals: trans_normals,
      count: trans_positions.length() / 3,
    },
  }
}

///|
/// Build only per-vertex colors for a chunk mesh split by material.
pub fn build_chunk_colors_split(
  registry : BlockRegistry,
  chunk_data : Array[UInt],
  chunk_light : Bytes,
  size : Int,
) -> MeshColorsSplit {
  let colors : Array[Float] = []
  let leaf_colors : Array[Float] = []
  let trans_colors : Array[Float] = []
  let get_index = fn(x : Int, y : Int, z : Int) -> Int {
    (y * size + z) * size + x
  }
  let data_len = chunk_data.length()
  let light_len = chunk_light.length()
  let base_len = size * size * size
  let pad = size + 2
  let pad_len = pad * pad * pad
  let get_light = fn(x : Int, y : Int, z : Int) -> Int {
    if light_len == base_len {
      if x < 0 || x >= size || y < 0 || y >= size || z < 0 ||
        z >= size {
        15
      } else {
        let idx = get_index(x, y, z)
        chunk_light[idx].to_int()
      }
    } else if light_len == pad_len {
      let px = x + 1
      let py = y + 1
      let pz = z + 1
      if px < 0 || px >= pad || py < 0 || py >= pad || pz < 0 ||
        pz >= pad {
        0
      } else {
        let idx = (py * pad + pz) * pad + px
        chunk_light[idx].to_int()
      }
    } else {
      15
    }
  }
  let push_color_into = fn(
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
  let air_block = match registry.get_by_name("air") {
    Some(block) => block
    None => return MeshColorsSplit::{ normal: [], leaf: [], translucent: [] }
  }
  let get_block = fn(x : Int, y : Int, z : Int) -> RenderBlock {
    if data_len == base_len {
      if x < 0 || x >= size || y < 0 || y >= size || z < 0 || z >= size {
        air_block
      } else {
        let idx = get_index(x, y, z)
        match registry.get_by_long_id(chunk_data[idx]) {
          Some(block) => block
          None => air_block
        }
      }
    } else if data_len == pad_len {
      let px = x + 1
      let py = y + 1
      let pz = z + 1
      if px < 0 || px >= pad || py < 0 || py >= pad || pz < 0 ||
        pz >= pad {
        air_block
      } else {
        let idx = (py * pad + pz) * pad + px
        match registry.get_by_long_id(chunk_data[idx]) {
          Some(block) => block
          None => air_block
        }
      }
    } else {
      air_block
    }
  }
  for x in 0..<size {
    for y in 0..<size {
      for z in 0..<size {
        let block = get_block(x, y, z)
        if block.block.shape is Shape::Air {
          continue
        }
        let model = block.block.shape.model()
        let render_info = @shape.FaceSource::{
          faces: block.faces,
          state: block.block.state,
        }
        let is_double_sided = (model.double_sided)(render_info)
        let target = if block.block.material is Material::TintedLeaf {
          leaf_colors
        } else if block.block.alpha_mode is AlphaMode::Translucent {
          trans_colors
        } else {
          colors
        }
        let tint = block.block.material.tint()
        let push_color_alpha = fn(
          count : Int,
          color_scale : Float,
          alpha_scale : Float,
        ) -> Unit {
          push_color_into(target, count, color_scale, tint, alpha_scale)
        }
        let push_color = fn(count : Int, color_scale : Float) -> Unit {
          push_color_alpha(count, color_scale, 1.0F)
        }
        if (model.emit_colors)(render_info, push_color) {
          continue
        }
        for face in @shape.faces {
          let (nx, ny, nz) = face.normal
          let neighbor = get_block(x + nx, y + ny, z + nz)
          let occlusion = @shape.FaceOcclusion::{
            neighbor_occludes: neighbor.block.occlusion_cull,
            same_block_cull: block.block.inter_cull && block.long_id == neighbor.long_id,
          }
          let visible = (model.face_visible)(render_info, face, occlusion)
          let boundary_transparent = is_chunk_boundary_face(
            x,
            y,
            z,
            nx,
            ny,
            nz,
            size,
          ) && !block.block.occlusion_cull
          if visible || boundary_transparent {
            let light = get_light(x + nx, y + ny, z + nz)
            let light_scale = @util.light_level_scale(light)
            let shade = @util.face_shade_scale(nx, ny, nz)
            let color_scale = shade * light_scale
            let alpha_scale = if boundary_transparent && !visible {
              0.0F
            } else {
              1.0F
            }
            let count = if is_double_sided { 12 } else { 6 }
            push_color_alpha(count, color_scale, alpha_scale)
          }
        }
      }
    }
  }
  MeshColorsSplit::{ normal: colors, leaf: leaf_colors, translucent: trans_colors }
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
  let mut tint_r = 1.0F
  let mut tint_g = 1.0F
  let mut tint_b = 1.0F
  let mut tint_a = 1.0F
  let get_index = fn(x : Int, y : Int, z : Int) -> Int {
    (y * size + z) * size + x
  }
  let data_len = chunk_data.length()
  let light_len = chunk_light.length()
  let base_len = size * size * size
  let pad = size + 2
  let pad_len = pad * pad * pad
  let get_light = fn(x : Int, y : Int, z : Int) -> Int {
    if light_len == base_len {
      if x < 0 || x >= size || y < 0 || y >= size || z < 0 ||
        z >= size {
        15
      } else {
        let idx = get_index(x, y, z)
        chunk_light[idx].to_int()
      }
    } else if light_len == pad_len {
      let px = x + 1
      let py = y + 1
      let pz = z + 1
      if px < 0 || px >= pad || py < 0 || py >= pad || pz < 0 ||
        pz >= pad {
        0
      } else {
        let idx = (py * pad + pz) * pad + px
        chunk_light[idx].to_int()
      }
    } else {
      15
    }
  }
  let push_color_alpha = fn(count : Int, color_scale : Float, alpha_scale : Float) -> Unit {
    for _ in 0..<count {
      colors.push(color_scale * tint_r)
      colors.push(color_scale * tint_g)
      colors.push(color_scale * tint_b)
      colors.push(tint_a * alpha_scale)
    }
  }
  let push_color = fn(count : Int, color_scale : Float) -> Unit {
    push_color_alpha(count, color_scale, 1.0F)
  }
  let air_block = match registry.get_by_name("air") {
    Some(block) => block
    None => return []
  }
  let get_block = fn(x : Int, y : Int, z : Int) -> RenderBlock {
    if data_len == base_len {
      if x < 0 || x >= size || y < 0 || y >= size || z < 0 || z >= size {
        air_block
      } else {
        let idx = get_index(x, y, z)
        match registry.get_by_long_id(chunk_data[idx]) {
          Some(block) => block
          None => air_block
        }
      }
    } else if data_len == pad_len {
      let px = x + 1
      let py = y + 1
      let pz = z + 1
      if px < 0 || px >= pad || py < 0 || py >= pad || pz < 0 ||
        pz >= pad {
        air_block
      } else {
        let idx = (py * pad + pz) * pad + px
        match registry.get_by_long_id(chunk_data[idx]) {
          Some(block) => block
          None => air_block
        }
      }
    } else {
      air_block
    }
  }
  for x in 0..<size {
    for y in 0..<size {
      for z in 0..<size {
        let block = get_block(x, y, z)
        if block.block.shape is Shape::Air {
          continue
        }
        let (tr, tg, tb, ta) = block.block.material.tint()
        tint_r = tr
        tint_g = tg
        tint_b = tb
        tint_a = ta
        let model = block.block.shape.model()
        let render_info = @shape.FaceSource::{
          faces: block.faces,
          state: block.block.state,
        }
        if (model.emit_colors)(render_info, push_color) {
          continue
        }
        let is_double_sided = (model.double_sided)(render_info)
        for face in @shape.faces {
          let (nx, ny, nz) = face.normal
          let neighbor = get_block(x + nx, y + ny, z + nz)
          let occlusion = @shape.FaceOcclusion::{
            neighbor_occludes: neighbor.block.occlusion_cull,
            same_block_cull: block.block.inter_cull && block.long_id == neighbor.long_id,
          }
          let visible = (model.face_visible)(render_info, face, occlusion)
          let boundary_transparent = is_chunk_boundary_face(
            x,
            y,
            z,
            nx,
            ny,
            nz,
            size,
          ) && !block.block.occlusion_cull
          if visible || boundary_transparent {
            let light = get_light(x + nx, y + ny, z + nz)
            let light_scale = @util.light_level_scale(light)
            let shade = @util.face_shade_scale(nx, ny, nz)
            let color_scale = shade * light_scale
            let alpha_scale = if boundary_transparent && !visible {
              0.0F
            } else {
              1.0F
            }
            let count = if is_double_sided { 12 } else { 6 }
            push_color_alpha(count, color_scale, alpha_scale)
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
  let trans_positions : Array[Float] = []
  let trans_uvs : Array[Float] = []
  let trans_layers : Array[Float] = []
  let trans_colors : Array[Float] = []
  let trans_normals : Array[Float] = []
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
    let translucent = mesh.translucent
    for i in 0..<translucent.count {
      let pidx = i * 3
      trans_positions.push(translucent.positions[pidx] + offset_x)
      trans_positions.push(translucent.positions[pidx + 1] + offset_y)
      trans_positions.push(translucent.positions[pidx + 2] + offset_z)
      let uidx = i * 2
      trans_uvs.push(translucent.uvs[uidx])
      trans_uvs.push(translucent.uvs[uidx + 1])
      trans_layers.push(translucent.layers[i])
      let cidx = i * 4
      trans_colors.push(translucent.colors[cidx])
      trans_colors.push(translucent.colors[cidx + 1])
      trans_colors.push(translucent.colors[cidx + 2])
      trans_colors.push(translucent.colors[cidx + 3])
      let nidx = i * 3
      trans_normals.push(translucent.normals[nidx])
      trans_normals.push(translucent.normals[nidx + 1])
      trans_normals.push(translucent.normals[nidx + 2])
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
    translucent: MeshData::{
      positions: trans_positions,
      uvs: trans_uvs,
      layers: trans_layers,
      colors: trans_colors,
      normals: trans_normals,
      count: trans_positions.length() / 3,
    },
  }
}
