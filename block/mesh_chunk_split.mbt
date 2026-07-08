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
  let water_positions : Array[Float] = []
  let water_uvs : Array[Float] = []
  let water_layers : Array[Float] = []
  let water_colors : Array[Float] = []
  let water_normals : Array[Float] = []
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
        water: MeshData::{
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
        registry.get_by_long_id(chunk_data[idx]).unwrap_or(air_block)
      }
    } else if data_len == pad_len {
      let px = x + 1
      let py = y + 1
      let pz = z + 1
      if px < 0 || px >= pad || py < 0 || py >= pad || pz < 0 || pz >= pad {
        air_block
      } else {
        let idx = (py * pad + pz) * pad + px
        registry.get_by_long_id(chunk_data[idx]).unwrap_or(air_block)
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
    if block.block.is_water() {
      (water_positions, water_uvs, water_layers, water_colors, water_normals)
    } else if block.block.material is Material::TintedLeaf {
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
    let (positions_ref, uvs_ref, layers_ref, colors_ref, normals_ref) = select_arrays(
      block,
    )
    push_face_into(
      positions_ref, uvs_ref, layers_ref, colors_ref, normals_ref, a, b, c, d, normal,
      layer_f, uv_rect, flip_v, color_scale, tint, 1.0F,
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
    let (positions_ref, uvs_ref, layers_ref, colors_ref, normals_ref) = select_arrays(
      block,
    )
    push_face_rev_into(
      positions_ref, uvs_ref, layers_ref, colors_ref, normals_ref, a, b, c, d, normal,
      layer_f, uv_rect, flip_v, color_scale, tint, 1.0F,
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
    let (positions_ref, uvs_ref, layers_ref, colors_ref, normals_ref) = select_arrays(
      block,
    )
    push_face_rev_into(
      positions_ref, uvs_ref, layers_ref, colors_ref, normals_ref, a, b, c, d, normal,
      layer_f, uv_rect, flip_v, color_scale, tint, alpha_scale,
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
    let (positions_ref, uvs_ref, layers_ref, colors_ref, normals_ref) = select_arrays(
      block,
    )
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
        let model = model_by_block(block.block)
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
            same_block_cull: block.block.inter_cull &&
            block.long_id == neighbor.long_id,
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
    water: MeshData::{
      positions: water_positions,
      uvs: water_uvs,
      layers: water_layers,
      colors: water_colors,
      normals: water_normals,
      count: water_positions.length() / 3,
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
