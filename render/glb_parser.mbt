///|
const GLB_MAGIC = 0x46546c67
const GLB_JSON_TYPE = 0x4e4f534a
const GLB_BIN_TYPE = 0x004e4942

///|
pub struct GlbParseResult {
  json_text : String
  bin_data : ArrayBuffer?
}

///|
pub fn parse_glb(buffer : ArrayBuffer) -> GlbParseResult {
  let view = DataView::new(buffer)
  let magic = view.get_uint32_le(0)
  guard magic == GLB_MAGIC else { abort("invalid glb magic") }
  let version = view.get_uint32_le(4)
  guard version == 2 else { abort("unsupported glb version") }
  let total_len = view.get_uint32_le(8)
  let mut offset = 12
  let mut json_text = ""
  let mut bin_data : ArrayBuffer? = None
  while offset + 8 <= total_len {
    let chunk_len = view.get_uint32_le(offset)
    let chunk_type = view.get_uint32_le(offset + 4)
    offset += 8
    let chunk_end = offset + chunk_len
    if chunk_type == GLB_JSON_TYPE {
      let json_bytes = buffer.slice(offset, chunk_end)
      let decoder = TextDecoder::new_utf8()
      json_text = decoder.decode(json_bytes)
    } else if chunk_type == GLB_BIN_TYPE {
      bin_data = Some(buffer.slice(offset, chunk_end))
    }
    offset = chunk_end
  }
  guard json_text.length() > 0 else { abort("missing GLB JSON chunk") }
  { json_text, bin_data }
}
