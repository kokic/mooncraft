///|
pub fn build_chunk_colors_split(
  registry : @block.RenderRegistry,
  chunk_data : Array[UInt],
  chunk_light : Bytes,
  size : Int,
) -> MeshColorsSplit {
  let colors : Array[Float] = []
  let leaf_colors : Array[Float] = []
  let water_colors : Array[Float] = []
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
  let air_block = match registry.get_by_name(@schema.AIR_NAME) {
    Some(block) => block
    None =>
      return MeshColorsSplit::{
        normal: [],
        leaf: [],
        water: [],
        translucent: [],
      }
  }
  let get_block = fn(x : Int, y : Int, z : Int) -> @block.RenderBlock {
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
  for x in 0..<size {
    for y in 0..<size {
      for z in 0..<size {
        let render_block = get_block(x, y, z)
        if render_block.block.shape is @block.Shape::Air {
          continue
        }
        let model = @block.model_by_block(render_block.block)
        let render_info = @shape.FaceSource::{
          faces: render_block.faces,
          state: render_block.block.state,
        }
        let is_double_sided = (model.double_sided)(render_info)
        let target = if render_block.block.is_water() {
          water_colors
        } else if render_block.block.material is @block.Material::TintedLeaf {
          leaf_colors
        } else if render_block.block.alpha_mode is @block.AlphaMode::Translucent {
          trans_colors
        } else {
          colors
        }
        if render_block.block.shape is @block.Shape::Gltf {
          guard @gltf.block_gltf_model(render_block.block.name) is Some(model) else {
            continue
          }
          let light = get_light(x, y, z)
          let light_scale = @util.light_level_scale(light)
          emit_gltf_colors_into(model, light_scale, target)
          continue
        }
        let tint = render_block.block.material.tint()
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
            same_block_cull: render_block.block.inter_cull &&
            render_block.internal_id == neighbor.internal_id,
          }
          let visible = (model.face_visible)(render_info, face, occlusion)
          let boundary_transparent = is_chunk_boundary_face(
              x, y, z, nx, ny, nz, size,
            ) &&
            !render_block.block.occlusion_cull
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
  MeshColorsSplit::{
    normal: colors,
    leaf: leaf_colors,
    water: water_colors,
    translucent: trans_colors,
  }
}

///|
/// Build only per-vertex colors for a chunk mesh (same vertex order as build_chunk_mesh).
pub fn build_chunk_colors(
  registry : @block.RenderRegistry,
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
  let push_color_alpha = fn(
    count : Int,
    color_scale : Float,
    alpha_scale : Float,
  ) -> Unit {
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
  let air_block = match registry.get_by_name(@schema.AIR_NAME) {
    Some(block) => block
    None => return []
  }
  let get_block : (Int, Int, Int) -> @block.RenderBlock = (x, y, z) => {
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
  for x in 0..<size {
    for y in 0..<size {
      for z in 0..<size {
        let render_block = get_block(x, y, z)
        if render_block.block.shape is @block.Shape::Air {
          continue
        }
        let (tr, tg, tb, ta) = render_block.block.material.tint()
        tint_r = tr
        tint_g = tg
        tint_b = tb
        tint_a = ta
        let model = @block.model_by_block(render_block.block)
        let render_info = @shape.FaceSource::{
          faces: render_block.faces,
          state: render_block.block.state,
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
            same_block_cull: render_block.block.inter_cull &&
            render_block.internal_id == neighbor.internal_id,
          }
          let visible = (model.face_visible)(render_info, face, occlusion)
          let boundary_transparent = is_chunk_boundary_face(
              x, y, z, nx, ny, nz, size,
            ) &&
            !render_block.block.occlusion_cull
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
