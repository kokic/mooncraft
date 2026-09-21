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
      fetch_array_buffer(
        resolved,
        buffer => load.accept(index, buffer),
        on_error,
      )
    }
  }
}
