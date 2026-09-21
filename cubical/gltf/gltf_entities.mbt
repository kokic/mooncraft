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
pub fn GltfRenderer::add_entity(
  self : GltfRenderer,
  config : GltfEntityConfig,
) -> Unit {
  self.load_asset(config.url, asset => self.create_instance(config, asset))
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
  renderer.find_instance(id).map(instance => instance.model_position.copy())
}

///|
pub fn gltf_set_position(
  renderer : GltfRenderer,
  id : String,
  x : Double,
  y : Double,
  z : Double,
) -> Bool {
  guard renderer.find_instance(id) is Some(instance) else { false }
  instance.model_position[0] = x
  instance.model_position[1] = y
  instance.model_position[2] = z
  instance.refresh_model()
  true
}
