///|
fn component_count(type_name : String) -> Int {
  match type_name {
    "SCALAR" => 1
    "VEC2" => 2
    "VEC3" => 3
    "VEC4" => 4
    _ => abort("unsupported accessor type")
  }
}

///|
fn component_byte_size(component_type : Int) -> Int {
  if component_type == 5120 || component_type == 5121 {
    1
  } else if component_type == 5122 || component_type == 5123 {
    2
  } else if component_type == 5125 || component_type == 5126 {
    4
  } else {
    abort("unsupported component type")
  }
}

///|
fn read_component(
  view : @ffi.DataView,
  offset : Int,
  component_type : Int,
) -> Float {
  if component_type == 5120 {
    Float::from_int(view.get_int8(offset))
  } else if component_type == 5121 {
    Float::from_int(view.get_uint8(offset))
  } else if component_type == 5122 {
    Float::from_int(view.get_int16_le(offset))
  } else if component_type == 5123 {
    Float::from_int(view.get_uint16_le(offset))
  } else if component_type == 5125 {
    Float::from_int(view.get_uint32(offset))
  } else {
    Float::from_double(view.get_float32_le(offset))
  }
}

///|
pub fn read_accessor_values(
  buffer : @ffi.ArrayBuffer,
  component_type : Int,
  type_name : String,
  count : Int,
  byte_offset : Int,
  byte_stride : Int,
) -> @ffi.Float32Array {
  let comps = component_count(type_name)
  let comp_bytes = component_byte_size(component_type)
  let stride = if byte_stride > 0 { byte_stride } else { comp_bytes * comps }
  let view = @ffi.DataView::new(buffer)
  let out = @ffi.Float32Array::new(count * comps)
  let out_vals = out.values()
  let mut ptr = 0
  for i in 0..<count {
    let base = byte_offset + i * stride
    for c in 0..<comps {
      let off = base + c * comp_bytes
      out_vals[ptr] = read_component(view, off, component_type).to_double()
      ptr += 1
    }
  }
  out
}

///|
pub fn read_indices(
  buffer : @ffi.ArrayBuffer,
  component_type : Int,
  count : Int,
  byte_offset : Int,
  byte_stride : Int,
) -> @ffi.Float32Array {
  let comp_bytes = component_byte_size(component_type)
  let stride = if byte_stride > 0 { byte_stride } else { comp_bytes }
  let view = @ffi.DataView::new(buffer)
  let out = @ffi.Float32Array::new(count)
  let out_vals = out.values()
  for i in 0..<count {
    let off = byte_offset + i * stride
    let raw : Float = if component_type == 5125 {
      Float::from_int(view.get_uint32(off))
    } else {
      Float::from_int(view.get_uint16_le(off))
    }
    out_vals[i] = raw.to_double()
  }
  out
}
