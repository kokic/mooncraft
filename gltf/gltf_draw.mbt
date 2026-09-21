///|
priv struct GltfDrawEntry {
  primitive : GltfPrimitiveInstance
  model : @ffi.Float32Array
  mirrored : Bool
  texture : @webgl.WebGLTexture
  has_texture : Bool
  factor_r : Float
  factor_g : Float
  factor_b : Float
  factor_a : Float
  alpha_mask : Bool
  alpha_cutoff : Float
  double_sided : Bool
  distance_squared : Float
  light_scale : Float
}

///|
fn GltfInstance::material_for(
  self : GltfInstance,
  primitive : GltfPrimitiveInstance,
) -> (GltfMaterial, @webgl.WebGLTexture, Bool) {
  let material = self.asset.materials
    .get(primitive.material_index)
    .unwrap_or(self.asset.materials[0])
  let selected_texture = if self.texture_by_index.get(primitive.material_index) is Some(texture) {
    Some(texture)
  } else if material.name is Some(name) && self.texture_by_name.get(name) is Some(texture) {
    Some(texture)
  } else {
    self.default_texture
  }
  selected_texture.map_or(
    (material, material.texture, material.has_texture),
    texture => (material, texture, true),
  )
}

///|
fn sort_gltf_blend_entries(entries : Array[GltfDrawEntry]) -> Unit {
  for index in 1..<entries.length() {
    let entry = entries[index]
    let mut destination = index
    while destination > 0 &&
          entry.distance_squared > entries[destination - 1].distance_squared {
      entries[destination] = entries[destination - 1]
      destination -= 1
    }
    entries[destination] = entry
  }
}

///|
fn GltfRenderer::collect_draw_entries(
  self : GltfRenderer,
  camera_position : Array[Double],
) -> (Array[GltfDrawEntry], Array[GltfDrawEntry]) {
  let solid_entries : Array[GltfDrawEntry] = []
  let blend : Array[GltfDrawEntry] = []
  let world_center = [0.0, 0.0, 0.0]
  for instance in self.instances {
    for node_index, node in instance.asset.nodes {
      guard node.mesh >= 0 else { continue }
      guard instance.asset.meshes.get(node.mesh) is Some(mesh) else { continue }
      let model = @camera.mat4_create()
      ignore(
        @camera.mat4_mul(model, instance.model, instance.node_world[node_index]),
      )
      let m = model.values()
      let determinant = m[0] * (m[5] * m[10] - m[9] * m[6]) -
        m[4] * (m[1] * m[10] - m[9] * m[2]) +
        m[8] * (m[1] * m[6] - m[5] * m[2])
      // Zero scale hides the mesh and has no invertible normal transform.
      guard determinant != 0.0 else { continue }
      for primitive in mesh.primitives {
        let (material, texture, has_texture) = instance.material_for(primitive)
        ignore(
          @camera.transform_point(world_center, model, [
            primitive.center_x.to_double(),
            primitive.center_y.to_double(),
            primitive.center_z.to_double(),
          ]),
        )
        let dx = Float::from_double(world_center[0] - camera_position[0])
        let dy = Float::from_double(world_center[1] - camera_position[1])
        let dz = Float::from_double(world_center[2] - camera_position[2])
        let entry = GltfDrawEntry::{
          primitive,
          model,
          mirrored: determinant < 0.0,
          texture,
          has_texture,
          factor_r: material.factor_r,
          factor_g: material.factor_g,
          factor_b: material.factor_b,
          factor_a: material.factor_a,
          alpha_mask: material.alpha_mode == "MASK",
          alpha_cutoff: material.alpha_cutoff,
          double_sided: material.double_sided,
          distance_squared: dx * dx + dy * dy + dz * dz,
          light_scale: self.sample_light.map_or(1.0F, sample => {
            sample(world_center[0], world_center[1], world_center[2])
          }),
        }
        if material.alpha_mode == "BLEND" {
          blend.push(entry)
        } else {
          solid_entries.push(entry)
        }
      }
    }
  }
  sort_gltf_blend_entries(blend)
  (solid_entries, blend)
}

///|
fn draw_gltf_entries(
  gl : @webgl.WebGLRenderingContext,
  program : GltfProgramInfo,
  entries : Array[GltfDrawEntry],
  blend : Bool,
) -> Unit {
  if blend {
    gl.enable(@webgl.GL_BLEND)
    gl.blend_func(@webgl.GL_SRC_ALPHA, @webgl.GL_ONE_MINUS_SRC_ALPHA)
    gl.depth_mask(false)
  } else {
    gl.disable(@webgl.GL_BLEND)
    gl.depth_mask(true)
  }
  gl.uniform_1i(program.u_alpha_blend, if blend { 1 } else { 0 })
  for entry in entries {
    gl.front_face(if entry.mirrored { @webgl.GL_CW } else { @webgl.GL_CCW })
    gl.uniform_matrix4fv(program.u_model, false, entry.model)
    gl.uniform_1f(program.u_light_scale, entry.light_scale)
    gl.uniform_1i(program.u_has_texture, if entry.has_texture { 1 } else { 0 })
    gl.uniform_4f(
      program.u_color,
      entry.factor_r,
      entry.factor_g,
      entry.factor_b,
      entry.factor_a,
    )
    gl.uniform_1i(program.u_alpha_mask, if entry.alpha_mask { 1 } else { 0 })
    gl.uniform_1f(program.u_alpha_cutoff, entry.alpha_cutoff)
    if entry.double_sided {
      gl.disable(@webgl.GL_CULL_FACE)
    } else {
      gl.enable(@webgl.GL_CULL_FACE)
    }
    gl.active_texture(33984)
    gl.bind_texture_2d(entry.texture)
    gl.bind_vertex_array(entry.primitive.vao)
    if entry.primitive.index_buf is Some(_) {
      gl.draw_elements(
          @webgl.GL_TRIANGLES,
          entry.primitive.count,
          entry.primitive.index_type,
          0,
        )
    } else {
      gl.draw_arrays(@webgl.GL_TRIANGLES, 0, entry.primitive.count)
    }
  }
  gl.unbind_vertex_array()
  if blend {
    gl.depth_mask(true)
    gl.disable(@webgl.GL_BLEND)
  }
}

///|
fn GltfRenderer::draw_entries(
  self : GltfRenderer,
  entries : Array[GltfDrawEntry],
  blend : Bool,
  view : @ffi.Float32Array,
  view_projection : @ffi.Float32Array,
  fog_color : Array[Double],
  fog_near : Double,
  fog_far : Double,
) -> Unit {
  guard entries.length() > 0 else { () }
  let gl = self.gl
  let program = self.program
  gl.use_program(program.program)
  gl.uniform_matrix4fv(program.u_view, false, view)
  gl.uniform_matrix4fv(program.u_view_proj, false, view_projection)
  gl.uniform_3f(
    program.u_fog_color,
    Float::from_double(fog_color[0]),
    Float::from_double(fog_color[1]),
    Float::from_double(fog_color[2]),
  )
  gl.uniform_1f(program.u_fog_near, Float::from_double(fog_near))
  gl.uniform_1f(program.u_fog_far, Float::from_double(fog_far))
  gl.uniform_1i(program.u_tex, 0)
  gl.front_face(@webgl.GL_CCW)
  draw_gltf_entries(gl, program, entries, blend)
  gl.unbind_texture_2d()
  gl.front_face(@webgl.GL_CW)
  gl.enable(@webgl.GL_CULL_FACE)
}
