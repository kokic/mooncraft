///|
priv struct GltfAssetBuild {
  renderer : GltfRenderer
  url : String
  root : Json
  buffers : Array[@ffi.ArrayBuffer?]
}

///|
fn GltfRenderer::finish_asset(
  self : GltfRenderer,
  url : String,
  asset : GltfAsset,
) -> Unit {
  guard self.assets.get(url) is Some(Loading(callbacks)) else { () }
  self.assets[url] = Ready(asset)
  callbacks.each(callback => callback(asset))
}

///|
fn GltfRenderer::fail_asset(
  self : GltfRenderer,
  url : String,
  message : String,
) -> Unit {
  self.assets[url] = Failed
  log_gltf_error("failed to load \{url}: \{message}")
}

///|
extern "js" fn log_gltf_error(message : String) -> Unit =
  #| (message) => console.error(`[gltf] ${message}`)

///|
fn GltfRenderer::load_asset(
  self : GltfRenderer,
  url : String,
  on_load : (GltfAsset) -> Unit,
) -> Unit {
  let absolute_url = absolute_asset_url(url)
  match self.assets.get(absolute_url) {
    Some(Ready(asset)) => on_load(asset)
    Some(Loading(callbacks)) => callbacks.push(on_load)
    Some(Failed) => ()
    None => {
      self.assets[absolute_url] = Loading([on_load])
      fetch_array_buffer(
        absolute_url,
        buffer => self.decode_asset_response(absolute_url, buffer),
        message => self.fail_asset(absolute_url, message),
      )
    }
  }
}

///|
fn GltfRenderer::decode_asset_response(
  self : GltfRenderer,
  url : String,
  buffer : @ffi.ArrayBuffer,
) -> Unit {
  let (json_text, glb_bin) = if is_glb_buffer(buffer) {
    let parsed = parse_glb(buffer)
    (parsed.json_text, parsed.bin_data)
  } else {
    (array_buffer_to_text(buffer), None)
  }
  try @json.parse(json_text) catch {
    error => self.fail_asset(url, error.to_string())
  } noraise {
    root => self.load_asset_buffers(url, root, glb_bin)
  }
}

///|
fn GltfRenderer::load_asset_buffers(
  self : GltfRenderer,
  url : String,
  root : Json,
  glb_bin : @ffi.ArrayBuffer?,
) -> Unit {
  load_gltf_buffers(
    url,
    root,
    glb_bin,
    buffers => {
      let build = GltfAssetBuild::{ renderer: self, url, root, buffers }
      build.complete()
    },
    message => self.fail_asset(url, message),
  )
}

///|
priv struct GltfBufferLoad {
  buffers : Array[@ffi.ArrayBuffer?]
  mut remaining : Int
  on_ready : (Array[@ffi.ArrayBuffer?]) -> Unit
}

///|
fn GltfBufferLoad::accept(
  self : GltfBufferLoad,
  index : Int,
  buffer : @ffi.ArrayBuffer,
) -> Unit {
  guard self.buffers[index] is None else { () }
  self.buffers[index] = Some(buffer)
  self.remaining -= 1
  if self.remaining == 0 {
    (self.on_ready)(self.buffers)
  }
}

///|
/// Fetch every referenced glTF buffer (GLB BIN chunk, data URI, or external)
/// and invoke `on_ready` once all are available.
fn load_gltf_buffers(
  url : String,
  root : Json,
  glb_bin : @ffi.ArrayBuffer?,
  on_ready : (Array[@ffi.ArrayBuffer?]) -> Unit,
  on_error : (String) -> Unit,
) -> Unit {
  let fields = json_object(root)
  let definitions = json_array(json_field(fields, "buffers"))
  let load = GltfBufferLoad::{
    buffers: definitions.map(_ => None),
    remaining: definitions.length(),
    on_ready,
  }
  if definitions.length() == 0 {
    on_ready(load.buffers)
    return
  }
  for index, definition in definitions {
    let buffer_fields = json_object(definition)
    let uri = json_string(json_field(buffer_fields, "uri"))
    if uri.length() == 0 {
      match glb_bin {
        Some(buffer) => load.accept(index, buffer)
        None => on_error("buffer \{index} has no URI or GLB BIN chunk")
      }
    } else if is_data_uri(uri) {
      load.accept(index, decode_data_uri(uri))
    } else {
      let resolved = resolve_asset_url(url, uri)
      fetch_array_buffer(resolved, buffer => load.accept(index, buffer), message => {
        on_error(message)
      })
    }
  }
}

///|
fn read_accessor_from(
  root : Json,
  buffers : Array[@ffi.ArrayBuffer?],
  accessor_index : Int,
) -> @ffi.Float32Array? {
  let accessors = json_array(json_field(json_object(root), "accessors"))
  guard accessors.get(accessor_index) is Some(accessor_json) else { None }
  let accessor = json_object(accessor_json)
  let view_index = json_int(json_field(accessor, "bufferView"), fallback=-1)
  let views = json_array(json_field(json_object(root), "bufferViews"))
  guard views.get(view_index) is Some(view_json) else { None }
  let view = json_object(view_json)
  let buffer_index = json_int(json_field(view, "buffer"), fallback=-1)
  guard buffers.get(buffer_index) is Some(Some(buffer)) else { None }
  let offset = json_int(json_field(view, "byteOffset")) +
    json_int(json_field(accessor, "byteOffset"))
  let stride = json_int(json_field(view, "byteStride"))
  let component_type = json_int(json_field(accessor, "componentType"))
  let count = json_int(json_field(accessor, "count"))
  let type_name = json_string(json_field(accessor, "type"))
  Some(
    read_accessor_values(
      buffer, component_type, type_name, count, offset, stride,
    ),
  )
}

///|
fn read_indices_from(
  root : Json,
  buffers : Array[@ffi.ArrayBuffer?],
  accessor_index : Int,
) -> @ffi.Float32Array? {
  let accessors = json_array(json_field(json_object(root), "accessors"))
  guard accessors.get(accessor_index) is Some(accessor_json) else { None }
  let accessor = json_object(accessor_json)
  let view_index = json_int(json_field(accessor, "bufferView"), fallback=-1)
  let views = json_array(json_field(json_object(root), "bufferViews"))
  guard views.get(view_index) is Some(view_json) else { None }
  let view = json_object(view_json)
  let buffer_index = json_int(json_field(view, "buffer"), fallback=-1)
  guard buffers.get(buffer_index) is Some(Some(buffer)) else { None }
  let offset = json_int(json_field(view, "byteOffset")) +
    json_int(json_field(accessor, "byteOffset"))
  Some(
    read_indices(
      buffer,
      json_int(json_field(accessor, "componentType")),
      json_int(json_field(accessor, "count")),
      offset,
      json_int(json_field(view, "byteStride")),
    ),
  )
}

///|
fn GltfAssetBuild::read_accessor(
  self : GltfAssetBuild,
  accessor_index : Int,
) -> @ffi.Float32Array? {
  read_accessor_from(self.root, self.buffers, accessor_index)
}

///|
fn GltfAssetBuild::read_indices(
  self : GltfAssetBuild,
  accessor_index : Int,
) -> @ffi.Float32Array? {
  read_indices_from(self.root, self.buffers, accessor_index)
}

///|
fn GltfAssetBuild::parse_nodes(self : GltfAssetBuild) -> Array[GltfNode] {
  parse_nodes(self.root)
}

///|
fn parse_nodes(root : Json) -> Array[GltfNode] {
  let definitions = json_array(json_field(json_object(root), "nodes"))
  definitions.map(definition => {
    let fields = json_object(definition)
    let identity = @camera.mat4_create()
    let matrix_json = json_field(fields, "matrix")
    let matrix = if json_array(matrix_json).length() == 16 {
      Some(json_float32_array(matrix_json, 16, identity))
    } else {
      None
    }
    {
      mesh: json_int(json_field(fields, "mesh"), fallback=-1),
      children: json_int_array(json_field(fields, "children")),
      translation: json_double_array(json_field(fields, "translation"), 3, [
        0.0, 0.0, 0.0,
      ]),
      rotation: json_double_array(json_field(fields, "rotation"), 4, [
        0.0, 0.0, 0.0, 1.0,
      ]),
      scale: json_double_array(json_field(fields, "scale"), 3, [1.0, 1.0, 1.0]),
      matrix,
    }
  })
}

///|
priv struct GltfMaterialMeta {
  name : String?
  texture_index : Int
  factor_r : Float
  factor_g : Float
  factor_b : Float
  factor_a : Float
  alpha_mode : String
  alpha_cutoff : Float
  double_sided : Bool
}

///|
/// Shared material metadata extraction (base color factor, alpha mode, etc.).
fn parse_material_meta(root : Json, index : Int) -> GltfMaterialMeta {
  let definitions = json_array(json_field(json_object(root), "materials"))
  guard definitions.get(index) is Some(definition) else {
    return GltfMaterialMeta::{
      name: None,
      texture_index: -1,
      factor_r: 1.0F,
      factor_g: 1.0F,
      factor_b: 1.0F,
      factor_a: 1.0F,
      alpha_mode: "OPAQUE",
      alpha_cutoff: 0.5F,
      double_sided: false,
    }
  }
  let fields = json_object(definition)
  let pbr = json_object(json_field(fields, "pbrMetallicRoughness"))
  let factor = json_double_array(json_field(pbr, "baseColorFactor"), 4, [
    1.0, 1.0, 1.0, 1.0,
  ])
  let texture_info = json_object(json_field(pbr, "baseColorTexture"))
  let name = match json_field(fields, "name") {
    String(value) => Some(value)
    _ => None
  }
  GltfMaterialMeta::{
    name,
    texture_index: json_int(json_field(texture_info, "index"), fallback=-1),
    factor_r: Float::from_double(factor[0]),
    factor_g: Float::from_double(factor[1]),
    factor_b: Float::from_double(factor[2]),
    factor_a: Float::from_double(factor[3]),
    alpha_mode: json_string(json_field(fields, "alphaMode"), fallback="OPAQUE"),
    alpha_cutoff: Float::from_double(
      json_double(json_field(fields, "alphaCutoff"), fallback=0.5),
    ),
    double_sided: json_bool(json_field(fields, "doubleSided")),
  }
}

///|
fn GltfAssetBuild::parse_materials(
  self : GltfAssetBuild,
) -> Array[GltfMaterial] {
  let definitions = json_array(json_field(json_object(self.root), "materials"))
  let materials : Array[GltfMaterial] = []
  for index in 0..<definitions.length() {
    let meta = parse_material_meta(self.root, index)
    materials.push(GltfMaterial::{
      name: meta.name,
      texture_index: meta.texture_index,
      texture: self.renderer.white_texture,
      has_texture: false,
      factor_r: meta.factor_r,
      factor_g: meta.factor_g,
      factor_b: meta.factor_b,
      factor_a: meta.factor_a,
      alpha_mode: meta.alpha_mode,
      alpha_cutoff: meta.alpha_cutoff,
      double_sided: meta.double_sided,
    })
  }
  if materials.length() == 0 {
    let meta = parse_material_meta(self.root, 0)
    materials.push(GltfMaterial::{
      name: meta.name,
      texture_index: meta.texture_index,
      texture: self.renderer.white_texture,
      has_texture: false,
      factor_r: meta.factor_r,
      factor_g: meta.factor_g,
      factor_b: meta.factor_b,
      factor_a: meta.factor_a,
      alpha_mode: meta.alpha_mode,
      alpha_cutoff: meta.alpha_cutoff,
      double_sided: meta.double_sided,
    })
  }
  materials
}

///|
fn GltfAssetBuild::parse_meshes(self : GltfAssetBuild) -> Array[GltfMesh] {
  let definitions = json_array(json_field(json_object(self.root), "meshes"))
  definitions.map(definition => {
    let fields = json_object(definition)
    let primitives : Array[GltfPrimitiveInstance] = []
    for primitive_json in json_array(json_field(fields, "primitives")) {
      let primitive = json_object(primitive_json)
      guard json_int(json_field(primitive, "mode"), fallback=4) == 4 else {
        continue
      }
      let attributes = json_object(json_field(primitive, "attributes"))
      let position_index = json_int(
        json_field(attributes, "POSITION"),
        fallback=-1,
      )
      guard self.read_accessor(position_index) is Some(positions) else {
        continue
      }
      let normal_index = json_int(json_field(attributes, "NORMAL"), fallback=-1)
      let uv_index = json_int(json_field(attributes, "TEXCOORD_0"), fallback=-1)
      let index_index = json_int(json_field(primitive, "indices"), fallback=-1)
      let normals = self
        .read_accessor(normal_index)
        .unwrap_or(@ffi.Float32Array::new(0))
      let uvs = self
        .read_accessor(uv_index)
        .unwrap_or(@ffi.Float32Array::new(0))
      let indices = self
        .read_indices(index_index)
        .unwrap_or(@ffi.Float32Array::new(0))
      primitives.push(
        build_gltf_primitive(
          self.renderer.gl,
          self.renderer.program,
          positions,
          normals,
          uvs,
          indices,
          json_int(json_field(primitive, "material")),
        ),
      )
    }
    { primitives, }
  })
}

///|
fn GltfAssetBuild::parse_animations(
  self : GltfAssetBuild,
) -> Array[GltfAnimation] {
  let definitions = json_array(json_field(json_object(self.root), "animations"))
  definitions.map(animation_json => {
    let animation = json_object(animation_json)
    let samplers = json_array(json_field(animation, "samplers"))
    let channels : Array[GltfAnimationChannel] = []
    let mut duration = 0.0F
    for channel_json in json_array(json_field(animation, "channels")) {
      let channel = json_object(channel_json)
      let sampler_index = json_int(json_field(channel, "sampler"), fallback=-1)
      guard samplers.get(sampler_index) is Some(sampler_json) else { continue }
      let sampler = json_object(sampler_json)
      let target = json_object(json_field(channel, "target"))
      let path = json_string(json_field(target, "path"))
      guard path == "translation" || path == "rotation" || path == "scale" else {
        continue
      }
      guard self.read_accessor(
          json_int(json_field(sampler, "input"), fallback=-1),
        )
        is Some(input) else {
        continue
      }
      guard self.read_accessor(
          json_int(json_field(sampler, "output"), fallback=-1),
        )
        is Some(output) else {
        continue
      }
      if input.length() > 0 {
        let end = Float::from_double(input.values()[input.length() - 1])
        if end > duration {
          duration = end
        }
      }
      channels.push({
        node: json_int(json_field(target, "node"), fallback=-1),
        path,
        interpolation: json_string(
          json_field(sampler, "interpolation"),
          fallback="LINEAR",
        ),
        input,
        output,
      })
    }
    { name: json_string(json_field(animation, "name")), duration, channels }
  })
}

///|
fn GltfAssetBuild::parse_roots(self : GltfAssetBuild) -> Array[Int] {
  parse_roots(self.root)
}

///|
fn parse_roots(root : Json) -> Array[Int] {
  let root_json = json_object(root)
  let scenes = json_array(json_field(root_json, "scenes"))
  let scene_index = json_int(json_field(root_json, "scene"))
  guard scenes.get(scene_index) is Some(scene_json) else { [] }
  json_int_array(json_field(json_object(scene_json), "nodes"))
}

///|
fn GltfAssetBuild::complete(self : GltfAssetBuild) -> Unit {
  let asset = GltfAsset::{
    nodes: self.parse_nodes(),
    meshes: self.parse_meshes(),
    roots: self.parse_roots(),
    materials: self.parse_materials(),
    animations: self.parse_animations(),
  }
  self.load_material_textures(asset)
  self.renderer.finish_asset(self.url, asset)
}

///|
fn GltfAssetBuild::load_material_textures(
  self : GltfAssetBuild,
  asset : GltfAsset,
) -> Unit {
  let root = json_object(self.root)
  let textures = json_array(json_field(root, "textures"))
  let images = json_array(json_field(root, "images"))
  let samplers = json_array(json_field(root, "samplers"))
  for material in asset.materials {
    guard textures.get(material.texture_index) is Some(texture_json) else {
      continue
    }
    let texture = json_object(texture_json)
    let source_index = json_int(json_field(texture, "source"), fallback=-1)
    guard images.get(source_index) is Some(image_json) else { continue }
    let image = json_object(image_json)
    let sampler_index = json_int(json_field(texture, "sampler"), fallback=-1)
    let sampler = match samplers.get(sampler_index) {
      Some(value) => json_object(value)
      None => {}
    }
    let min_filter = json_int(json_field(sampler, "minFilter"), fallback=9728)
    let mag_filter = json_int(json_field(sampler, "magFilter"), fallback=9728)
    let wrap_s = json_int(json_field(sampler, "wrapS"), fallback=33071)
    let wrap_t = json_int(json_field(sampler, "wrapT"), fallback=33071)
    let accept = fn(image_value : @ffi.JsValue) -> Unit {
      material.texture = create_texture_from_image(
        self.renderer.gl,
        image_value,
        min_filter,
        mag_filter,
        wrap_s,
        wrap_t,
      )
      material.has_texture = true
    }
    let uri = json_string(json_field(image, "uri"))
    if uri.length() > 0 {
      let resolved = if is_data_uri(uri) {
        uri
      } else {
        resolve_asset_url(self.url, uri)
      }
      load_image_url(resolved, accept, log_gltf_error)
      continue
    }
    let view_index = json_int(json_field(image, "bufferView"), fallback=-1)
    let views = json_array(json_field(root, "bufferViews"))
    guard views.get(view_index) is Some(view_json) else { continue }
    let view = json_object(view_json)
    let buffer_index = json_int(json_field(view, "buffer"), fallback=-1)
    guard self.buffers.get(buffer_index) is Some(Some(buffer)) else { continue }
    let offset = json_int(json_field(view, "byteOffset"))
    let length = json_int(json_field(view, "byteLength"))
    let bytes = buffer.slice(offset, offset + length)
    let mime_type = json_string(
      json_field(image, "mimeType"),
      fallback="image/png",
    )
    load_image_buffer(bytes, mime_type, accept, log_gltf_error)
  }
}
