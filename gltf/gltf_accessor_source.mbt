///|
/// Resolved buffer layout shared by attribute and index decoding.
priv struct GltfAccessorSource {
  buffer : @ffi.ArrayBuffer
  component_type : Int
  type_name : String
  count : Int
  offset : Int
  stride : Int
}

///|
fn resolve_accessor_source(
  root : Json,
  buffers : Array[@ffi.ArrayBuffer?],
  accessor_index : Int,
) -> GltfAccessorSource? {
  let fields = json_object(root)
  let accessors = json_array(json_field(fields, "accessors"))
  guard accessors.get(accessor_index) is Some(accessor_json) else { None }
  let accessor = json_object(accessor_json)
  let views = json_array(json_field(fields, "bufferViews"))
  let view_index = json_int(json_field(accessor, "bufferView"), fallback=-1)
  guard views.get(view_index) is Some(view_json) else { None }
  let view = json_object(view_json)
  let buffer_index = json_int(json_field(view, "buffer"), fallback=-1)
  guard buffers.get(buffer_index) is Some(Some(buffer)) else { None }
  Some({
    buffer,
    component_type: json_int(json_field(accessor, "componentType")),
    type_name: json_string(json_field(accessor, "type")),
    count: json_int(json_field(accessor, "count")),
    offset: json_int(json_field(view, "byteOffset")) + json_int(json_field(accessor, "byteOffset")),
    stride: json_int(json_field(view, "byteStride")),
  })
}

///|
fn read_accessor_from(
  root : Json,
  buffers : Array[@ffi.ArrayBuffer?],
  accessor_index : Int,
) -> @ffi.Float32Array? {
  guard resolve_accessor_source(root, buffers, accessor_index) is Some(source) else { None }
  Some(read_accessor_values(
    source.buffer, source.component_type, source.type_name, source.count, source.offset, source.stride,
  ) catch {
    error => {
      log_gltf_error("skipping accessor \{accessor_index}: \{error.message()}")
      return None
    }
  })
}

///|
fn read_indices_from(
  root : Json,
  buffers : Array[@ffi.ArrayBuffer?],
  accessor_index : Int,
) -> @ffi.Float32Array? {
  guard resolve_accessor_source(root, buffers, accessor_index) is Some(source) else { None }
  Some(read_indices(
    source.buffer, source.component_type, source.count, source.offset, source.stride,
  ) catch {
    error => {
      log_gltf_error("skipping indices \{accessor_index}: \{error.message()}")
      return None
    }
  })
}
