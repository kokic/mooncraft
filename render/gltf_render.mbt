///|
priv struct DrawEntry {
  vao : WebGLVertexArray
  index_buf : WebGLBuffer?
  index_type : Int
  count : Int
  model : Float32Array
  texture : WebGLTexture
  has_texture : Bool
  factor_r : Float
  factor_g : Float
  factor_b : Float
  factor_a : Float
  alpha_mask : Bool
  alpha_cutoff : Float
  double_sided : Bool
  dist_sq : Float
}

///|
fn sort_descending(list : Array[DrawEntry]) -> Array[DrawEntry] {
  let n = list.length()
  if n <= 1 { return list }
  let sorted : Array[DrawEntry] = []
  for i in 0..<n {
    let entry = list[i]
    let mut inserted = false
    for j in 0..<sorted.length() {
      if entry.dist_sq > sorted[j].dist_sq {
        sorted.insert(j, entry)
        inserted = true
        break
      }
    }
    if !inserted { sorted.push(entry) }
  }
  sorted
}

///|
fn resolve_material(
  mat : GltfMaterialInstance,
  prim_idx : Int,
  tex_by_idx : Map[Int, WebGLTexture],
  tex_by_name : Map[String, WebGLTexture],
  fallback_tex : WebGLTexture?,
) -> GltfMaterialInstance {
  let override_tex = match tex_by_idx.get(prim_idx) {
    Some(tex) => Some(tex)
    None => match mat.name {
      Some(name) => tex_by_name.get(name)
      None => fallback_tex
    }
  }
  match override_tex {
    Some(tex) => GltfMaterialInstance::{
      name: mat.name, texture: tex, has_texture: true,
      factor_r: mat.factor_r, factor_g: mat.factor_g, factor_b: mat.factor_b, factor_a: mat.factor_a,
      alpha_mode: mat.alpha_mode, alpha_cutoff: mat.alpha_cutoff, double_sided: mat.double_sided,
    }
    None => mat
  }
}

///|
pub fn render_entities(
  gl : WebGLRenderingContext,
  info : GltfProgramInfo,
  instances : Array[GltfEntityInstance],
  view_mat : Float32Array,
  view_proj_mat : Float32Array,
  cam_pos : Array[Double],
  fog_r : Float,
  fog_g : Float,
  fog_b : Float,
  fog_near : Float,
  fog_far : Float,
) -> Unit {
  let solid : Array[DrawEntry] = []
  let mut blend : Array[DrawEntry] = []
  for inst in instances {
    for ni in 0..<inst.nodes_len {
      let node_world = inst.node_world[ni]
      let n_meshes = inst.meshes.length()
      for mi in 0..<n_meshes {
        let prims = inst.meshes[mi].primitives
        let model_node = mat4_create()
        ignore(mat4_mul(model_node, inst.model, node_world))
        for prim in prims {
          let mat = resolve_material(
            inst.materials[prim.material_index], prim.material_index,
            inst.tex_overrides_by_index, inst.tex_overrides_by_name,
            inst.default_tex_override,
          )
          let is_blend = mat.alpha_mode == "BLEND" || mat.factor_a < 0.999F
          let cx = prim.center_x
          let cy = prim.center_y
          let cz = prim.center_z
          let wx = Float::from_double(cam_pos[0])
          let wy = Float::from_double(cam_pos[1])
          let wz = Float::from_double(cam_pos[2])
          let dx = cx - wx
          let dy = cy - wy
          let dz = cz - wz
          let entry = DrawEntry::{
            vao: prim.vao, index_buf: prim.index_buf, index_type: prim.index_type,
            count: prim.count,
            model: model_node, texture: mat.texture,
            has_texture: mat.has_texture,
            factor_r: mat.factor_r, factor_g: mat.factor_g, factor_b: mat.factor_b, factor_a: mat.factor_a,
            alpha_mask: mat.alpha_mode == "MASK",
            alpha_cutoff: mat.alpha_cutoff, double_sided: mat.double_sided,
            dist_sq: dx * dx + dy * dy + dz * dz,
          }
          if is_blend { blend.push(entry) } else { solid.push(entry) }
        }
      }
    }
  }
  blend = sort_descending(blend)
  solid.append(blend)
  gl.use_program(info.program)
  gl.uniform_matrix4fv(info.u_view, false, view_mat)
  gl.uniform_matrix4fv(info.u_view_proj, false, view_proj_mat)
  gl.uniform_3f(info.u_fog_color, fog_r, fog_g, fog_b)
  gl.uniform_1f(info.u_fog_near, fog_near)
  gl.uniform_1f(info.u_fog_far, fog_far)
  gl.uniform_1i(info.u_tex, 0)
  gl.front_face(GL_CCW)
  draw_solid(gl, info, solid)
  draw_blend(gl, info, blend)
  gl.unbind_texture_2d()
  gl.front_face(GL_CW)
  gl.enable(GL_CULL_FACE)
}

///|
fn draw_solid(
  gl : WebGLRenderingContext,
  info : GltfProgramInfo,
  list : Array[DrawEntry],
) -> Unit {
  gl.disable(GL_BLEND)
  gl.depth_mask(true)
  for call in list {
    gl.uniform_matrix4fv(info.u_model, false, call.model)
    gl.uniform_1i(info.u_has_texture, if call.has_texture { 1 } else { 0 })
    gl.uniform_4f(info.u_color, call.factor_r, call.factor_g, call.factor_b, call.factor_a)
    gl.uniform_1i(info.u_alpha_mask, if call.alpha_mask { 1 } else { 0 })
    gl.uniform_1f(info.u_alpha_cutoff, call.alpha_cutoff)
    if call.double_sided { gl.disable(GL_CULL_FACE) } else { gl.enable(GL_CULL_FACE) }
    gl.active_texture(33984)
    gl.bind_texture_2d(call.texture)
    gl.bind_vertex_array(call.vao)
    match call.index_buf {
      Some(_) => gl.draw_elements(GL_TRIANGLES, call.count, call.index_type, 0)
      None => gl.draw_arrays(GL_TRIANGLES, 0, call.count)
    }
  }
  gl.unbind_vertex_array()
}

///|
fn draw_blend(
  gl : WebGLRenderingContext,
  info : GltfProgramInfo,
  list : Array[DrawEntry],
) -> Unit {
  if list.length() == 0 { return }
  gl.enable(GL_BLEND)
  gl.blend_func(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  gl.depth_mask(false)
  for call in list {
    gl.uniform_matrix4fv(info.u_model, false, call.model)
    gl.uniform_1i(info.u_has_texture, if call.has_texture { 1 } else { 0 })
    gl.uniform_4f(info.u_color, call.factor_r, call.factor_g, call.factor_b, call.factor_a)
    gl.uniform_1i(info.u_alpha_mask, if call.alpha_mask { 1 } else { 0 })
    gl.uniform_1f(info.u_alpha_cutoff, call.alpha_cutoff)
    if call.double_sided { gl.disable(GL_CULL_FACE) } else { gl.enable(GL_CULL_FACE) }
    gl.active_texture(33984)
    gl.bind_texture_2d(call.texture)
    gl.bind_vertex_array(call.vao)
    match call.index_buf {
      Some(_) => gl.draw_elements(GL_TRIANGLES, call.count, call.index_type, 0)
      None => gl.draw_arrays(GL_TRIANGLES, 0, call.count)
    }
  }
  gl.unbind_vertex_array()
  gl.depth_mask(true)
  gl.disable(GL_BLEND)
}
