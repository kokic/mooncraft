///|
priv struct GltfAssetBuild {
  renderer : GltfRenderer
  url : String
  root : Json
  buffers : Array[@ffi.ArrayBuffer?]
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
fn GltfAssetBuild::parse_materials(self : GltfAssetBuild) -> Array[GltfMaterial] {
  let definitions = json_array(json_field(json_object(self.root), "materials"))
  let count = if definitions.is_empty() { 1 } else { definitions.length() }
  let materials : Array[GltfMaterial] = []
  for index in 0..<count {
    materials.push(parse_material_meta(self.root, index).instantiate(self.renderer.white_texture))
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
    { name: json_string(json_field(animation, "name")), duration, channels, }
  })
}

///|
fn GltfAssetBuild::parse_roots(self : GltfAssetBuild) -> Array[Int] {
  parse_roots(self.root)
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
