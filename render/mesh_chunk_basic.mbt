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
        registry.get_by_internal_id(chunk_data[idx]).unwrap_or(air_block)
      }
    } else if data_len == pad_len {
      let px = x + 1
      let py = y + 1
      let pz = z + 1
      if px < 0 || px >= pad || py < 0 || py >= pad || pz < 0 || pz >= pad {
        air_block
      } else {
        let idx = (py * pad + pz) * pad + px
        registry.get_by_internal_id(chunk_data[idx]).unwrap_or(air_block)
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
      if px < 0 || px >= pad || py < 0 || py >= pad || pz < 0 || pz >= pad {
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
        if block.block.shape is @block.Shape::Air {
          continue
        }
        let (tr, tg, tb, ta) = block.block.material.tint()
        tint_r = tr
        tint_g = tg
        tint_b = tb
        tint_a = ta
        let model = @block.model_by_block(block.block)
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
            same_block_cull: block.block.inter_cull &&
            block.internal_id == neighbor.internal_id,
          }
          let visible = (model.face_visible)(render_info, face, occlusion)
          let boundary_transparent = is_chunk_boundary_face(
              x, y, z, nx, ny, nz, size,
            ) &&
            !block.block.occlusion_cull
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
