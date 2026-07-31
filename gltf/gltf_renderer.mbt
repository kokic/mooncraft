///|
priv struct GltfDrawEntry {
  primitive : GltfPrimitiveInstance
  model : @ffi.Float32Array
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
}

///|
fn GltfRenderer::load_texture(
  self : GltfRenderer,
  url : String,
  on_load : (@webgl.WebGLTexture) -> Unit,
) -> Unit {
  let absolute_url = absolute_asset_url(url)
  match self.textures.get(absolute_url) {
    Some(ReadyTexture(texture)) => on_load(texture)
    Some(LoadingTexture(callbacks)) => callbacks.push(on_load)
    Some(FailedTexture) => ()
    None => {
      self.textures[absolute_url] = LoadingTexture([on_load])
      load_image_url(
        absolute_url,
        image => {
          let texture = create_texture_from_image(
            self.gl,
            image,
            9728,
            9728,
            33071,
            33071,
          )
          guard self.textures.get(absolute_url)
            is Some(LoadingTexture(callbacks)) else {
            ()
          }
          self.textures[absolute_url] = ReadyTexture(texture)
          callbacks.each(callback => callback(texture))
        },
        message => {
          self.textures[absolute_url] = FailedTexture
          log_gltf_error(message)
        },
      )
    }
  }
}

///|
fn GltfAsset::animation_index(self : GltfAsset, name : String) -> Int {
  if name == "none" {
    return -1
  }
  for index, animation in self.animations {
    if animation.name == name {
      return index
    }
  }
  if self.animations.length() > 0 {
    0
  } else {
    -1
  }
}

///|
fn GltfRenderer::create_instance(
  self : GltfRenderer,
  config : GltfEntityConfig,
  asset : GltfAsset,
) -> Unit {
  let rotation = [0.0, 0.0, 0.0, 1.0]
  ignore(@camera.quat_normalize(rotation, config.rotation))
  ignore(@camera.quat_apply_yaw_offset(rotation, rotation, @math.PI))
  let model = @camera.mat4_create()
  ignore(@camera.mat4_from_trs(model, config.position, rotation, config.scale))
  let instance = GltfInstance::{
    id: config.id,
    asset,
    model,
    model_position: config.position.copy(),
    model_rotation: rotation.copy(),
    model_scale: config.scale.copy(),
    base_model_rotation: rotation.copy(),
    node_local: asset.nodes.map(_ => @camera.mat4_create()),
    node_world: asset.nodes.map(_ => @camera.mat4_create()),
    animation_index: asset.animation_index(config.animation),
    animation_time: 0.0F,
    animation_speed: Float::from_double(config.speed),
    animation_looped: config.looped,
    default_texture: None,
    texture_by_index: @hashmap.HashMap([]),
    texture_by_name: @hashmap.HashMap([]),
  }
  self.instances.push(instance)
  instance.update(0.0)
  if config.texture.length() > 0 {
    self.load_texture(config.texture, texture => {
      instance.default_texture = Some(texture)
    })
  }
  for texture_override in config.texture_overrides {
    self.load_texture(texture_override.texture, texture => {
      instance.texture_by_index[texture_override.index] = texture
    })
  }
  for material_override in config.material_texture_overrides {
    self.load_texture(material_override.texture, texture => {
      instance.texture_by_name[material_override.material] = texture
    })
  }
}

///|
pub fn create_gltf_renderer(
  gl : @webgl.WebGLRenderingContext,
  configs : Array[GltfEntityConfig],
) -> GltfRenderer {
  let renderer = GltfRenderer::{
    gl,
    program: create_gltf_program(gl, GLTF_VS_SOURCE, GLTF_FS_SOURCE),
    white_texture: create_white_texture(gl),
    assets: @hashmap.HashMap([]),
    textures: @hashmap.HashMap([]),
    instances: [],
  }
  for config in configs {
    renderer.load_asset(config.url, asset => {
      renderer.create_instance(config, asset)
    })
  }
  renderer
}

///|
pub fn GltfRenderer::add_entity(
  self : GltfRenderer,
  config : GltfEntityConfig,
) -> Unit {
  self.load_asset(config.url, asset => self.create_instance(config, asset))
}

///|
pub fn update_gltf_renderer(
  renderer : GltfRenderer,
  delta_seconds : Double,
) -> Unit {
  renderer.instances.each(instance => instance.update(delta_seconds))
}

///|
fn GltfInstance::material_for(
  self : GltfInstance,
  primitive : GltfPrimitiveInstance,
) -> (GltfMaterial, @webgl.WebGLTexture, Bool) {
  let material = self.asset.materials
    .get(primitive.material_index)
    .unwrap_or(self.asset.materials[0])
  let texture_override = match
    self.texture_by_index.get(primitive.material_index) {
    Some(texture) => Some(texture)
    None =>
      match material.name {
        Some(name) => self.texture_by_name.get(name)
        None => None
      }
  }
  let selected_texture = match texture_override {
    Some(texture) => Some(texture)
    None => self.default_texture
  }
  match selected_texture {
    Some(texture) => (material, texture, true)
    None => (material, material.texture, material.has_texture)
  }
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
        }
        if material.alpha_mode == "BLEND" || material.factor_a < 0.999F {
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
  for entry in entries {
    gl.uniform_matrix4fv(program.u_model, false, entry.model)
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
    match entry.primitive.index_buf {
      Some(_) =>
        gl.draw_elements(
          @webgl.GL_TRIANGLES,
          entry.primitive.count,
          entry.primitive.index_type,
          0,
        )
      None => gl.draw_arrays(@webgl.GL_TRIANGLES, 0, entry.primitive.count)
    }
  }
  gl.unbind_vertex_array()
  if blend {
    gl.depth_mask(true)
    gl.disable(@webgl.GL_BLEND)
  }
}

///|
pub fn render_gltf_renderer(
  renderer : GltfRenderer,
  view : @ffi.Float32Array,
  view_projection : @ffi.Float32Array,
  camera_position : Array[Double],
  fog_color : Array[Double],
  fog_near : Double,
  fog_far : Double,
) -> Unit {
  guard renderer.instances.length() > 0 else { () }
  let (solid_entries, blend) = renderer.collect_draw_entries(camera_position)
  let gl = renderer.gl
  let program = renderer.program
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
  draw_gltf_entries(gl, program, solid_entries, false)
  draw_gltf_entries(gl, program, blend, true)
  gl.unbind_texture_2d()
  gl.front_face(@webgl.GL_CW)
  gl.enable(@webgl.GL_CULL_FACE)
}

///|
fn GltfRenderer::find_instance(
  self : GltfRenderer,
  id : String,
) -> GltfInstance? {
  for instance in self.instances {
    if instance.id == id {
      return Some(instance)
    }
  }
  None
}

///|
fn GltfInstance::refresh_model(self : GltfInstance) -> Unit {
  ignore(@camera.quat_normalize(self.model_rotation, self.model_rotation))
  ignore(
    @camera.mat4_from_trs(
      self.model,
      self.model_position,
      self.model_rotation,
      self.model_scale,
    ),
  )
}

///|
pub fn gltf_set_animation(
  renderer : GltfRenderer,
  id : String,
  animation : String,
) -> Bool {
  guard renderer.find_instance(id) is Some(instance) else { false }
  instance.animation_index = instance.asset.animation_index(animation)
  instance.animation_time = 0.0F
  true
}

///|
pub fn gltf_set_texture(
  renderer : GltfRenderer,
  id : String,
  url : String,
) -> Bool {
  guard renderer.find_instance(id) is Some(instance) else { false }
  renderer.load_texture(url, texture => instance.default_texture = Some(texture))
  true
}

///|
pub fn gltf_set_rotation(
  renderer : GltfRenderer,
  id : String,
  x : Double,
  y : Double,
  z : Double,
  w : Double,
) -> Bool {
  guard renderer.find_instance(id) is Some(instance) else { false }
  ignore(
    @camera.quat_apply_yaw_offset(
      instance.model_rotation,
      [x, y, z, w],
      @math.PI,
    ),
  )
  instance.refresh_model()
  true
}

///|
pub fn gltf_set_yaw(renderer : GltfRenderer, id : String, yaw : Double) -> Bool {
  guard renderer.find_instance(id) is Some(instance) else { false }
  ignore(
    @camera.quat_apply_yaw_offset(
      instance.model_rotation,
      [0.0, 0.0, 0.0, 1.0],
      yaw + @math.PI,
    ),
  )
  instance.refresh_model()
  true
}

///|
pub fn gltf_set_scale(
  renderer : GltfRenderer,
  id : String,
  x : Double,
  y : Double,
  z : Double,
) -> Bool {
  guard renderer.find_instance(id) is Some(instance) else { false }
  guard x != 0.0 && y != 0.0 && z != 0.0 else { false }
  instance.model_scale[0] = x
  instance.model_scale[1] = y
  instance.model_scale[2] = z
  instance.refresh_model()
  true
}

///|
fn gltf_look_at(
  renderer : GltfRenderer,
  id : String,
  x : Double,
  y : Double,
  z : Double,
  with_pitch : Bool,
) -> Bool {
  guard renderer.find_instance(id) is Some(instance) else { false }
  let dx = x - instance.model_position[0]
  let dy = y - instance.model_position[1]
  let dz = z - instance.model_position[2]
  let horizontal = (dx * dx + dz * dz).sqrt()
  guard horizontal > 0.000001 || (with_pitch && dy.abs() > 0.000001) else {
    false
  }
  let yaw = @math.atan2(dz, dx)
  let pitch = if with_pitch { @math.atan2(dy, horizontal) } else { 0.0 }
  let look = [0.0, 0.0, 0.0, 1.0]
  ignore(@camera.quat_from_yaw_pitch(look, yaw, pitch))
  ignore(
    @camera.quat_mul(
      instance.model_rotation,
      look,
      instance.base_model_rotation,
    ),
  )
  instance.refresh_model()
  true
}

///|
pub fn gltf_look_at_xz(
  renderer : GltfRenderer,
  id : String,
  x : Double,
  z : Double,
) -> Bool {
  gltf_look_at(renderer, id, x, 0.0, z, false)
}

///|
pub fn gltf_look_at_xyz(
  renderer : GltfRenderer,
  id : String,
  x : Double,
  y : Double,
  z : Double,
) -> Bool {
  gltf_look_at(renderer, id, x, y, z, true)
}

///|
pub fn gltf_entity_ids(renderer : GltfRenderer) -> Array[String] {
  renderer.instances.map(instance => instance.id)
}

///|
pub fn gltf_entity_count(renderer : GltfRenderer) -> Int {
  renderer.instances.length()
}

///|
pub fn gltf_get_position(
  renderer : GltfRenderer,
  id : String,
) -> Array[Double]? {
  guard renderer.find_instance(id) is Some(instance) else { None }
  Some(instance.model_position.copy())
}

///|
pub fn gltf_set_position(
  renderer : GltfRenderer,
  id : String,
  x : Double,
  y : Double,
  z : Double,
) -> Bool {
  for instance in renderer.instances {
    guard instance.id == id else { continue }
    instance.model_position[0] = x
    instance.model_position[1] = y
    instance.model_position[2] = z
    instance.refresh_model()
    return true
  }
  false
}
