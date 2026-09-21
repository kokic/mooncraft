///|
pub fn build_gltf_primitive(
  gl : @webgl.WebGLRenderingContext,
  info : GltfProgramInfo,
  pos : @ffi.Float32Array,
  normal : @ffi.Float32Array,
  uv0 : @ffi.Float32Array,
  indices_data : @ffi.Float32Array,
  material_index : Int,
) -> GltfPrimitiveInstance {
  let vertex_count = pos.length() / 3
  // Build normals.
  let normals = if normal.length() == vertex_count * 3 {
    normal
  } else {
    let out = @ffi.Float32Array::new(vertex_count * 3)
    let out_vals = out.values()
    for i in 0..<vertex_count {
      out_vals[i * 3 + 1] = 1.0
    }
    out
  }
  // Build UVs.
  let uvs = if uv0.length() == vertex_count * 2 {
    uv0
  } else {
    @ffi.Float32Array::new(vertex_count * 2)
  }
  let vao = gl.create_vertex_array()
  gl.bind_vertex_array(vao)
  let pos_buf = upload_f32_attrib(gl, info.a_position, pos, 3)
  let n_buf = upload_f32_attrib(gl, info.a_normal, normals, 3)
  let uv_buf = upload_f32_attrib(gl, info.a_uv, uvs, 2)
  let (index_buf, index_type, count) = if indices_data.length() > 0 {
    let idx = indices_data
    let buf = gl.create_buffer()
    gl.bind_buffer(@webgl.GL_ELEMENT_ARRAY_BUFFER, buf)
    let needs_32 = has_index_32(idx)
    if needs_32 {
      gl.buffer_data_u32(
        @webgl.GL_ELEMENT_ARRAY_BUFFER,
        as_uint32(idx),
        @webgl.GL_STATIC_DRAW,
      )
    } else {
      gl.buffer_data_u16(
        @webgl.GL_ELEMENT_ARRAY_BUFFER,
        as_uint16(idx),
        @webgl.GL_STATIC_DRAW,
      )
    }
    (
      Some(buf),
      if needs_32 {
        @webgl.GL_UNSIGNED_INT
      } else {
        @webgl.GL_UNSIGNED_SHORT
      },
      idx.length(),
    )
  } else {
    (None, 0, vertex_count)
  }
  gl.unbind_vertex_array()

  let pos_vals = pos.values()
  let mut cx_f = 0.0F
  let mut cy_f = 0.0F
  let mut cz_f = 0.0F
  for i in 0..<vertex_count {
    let i3 = i * 3
    cx_f += Float::from_double(pos_vals[i3])
    cy_f += Float::from_double(pos_vals[i3 + 1])
    cz_f += Float::from_double(pos_vals[i3 + 2])
  }
  let vc = if vertex_count > 0 { vertex_count } else { 1 }
  let inv_n = 1.0F / Float::from_int(vc)
  {
    vao,
    pos_buf,
    n_buf,
    uv_buf,
    index_buf,
    index_type,
    count,
    material_index,
    center_x: cx_f * inv_n,
    center_y: cy_f * inv_n,
    center_z: cz_f * inv_n,
  }
}

///|
fn upload_f32_attrib(
  gl : @webgl.WebGLRenderingContext,
  attrib_index : Int,
  data : @ffi.Float32Array,
  comps : Int,
) -> @webgl.WebGLBuffer {
  let buf = gl.create_buffer()
  gl.bind_buffer(@webgl.GL_ARRAY_BUFFER, buf)
  gl.buffer_data_f32(@webgl.GL_ARRAY_BUFFER, data, @webgl.GL_STATIC_DRAW)
  gl.enable_vertex_attrib_array(attrib_index)
  gl.vertex_attrib_pointer(attrib_index, comps, @webgl.GL_FLOAT, false, 0, 0)
  buf
}

///|
fn has_index_32(data : @ffi.Float32Array) -> Bool {
  let vals = data.values()
  let len = data.length()
  let mut i = 0
  while i < len {
    if vals[i] > 65535.0 {
      return true
    }
    i += 1
  }
  false
}

///|
fn as_uint16(data : @ffi.Float32Array) -> @ffi.Uint16Array {
  let len = data.length()
  let out = @ffi.Uint16Array::new(len)
  js_copy_f32_to_u16(data, out, len)
  out
}

///|
extern "js" fn js_copy_f32_to_u16(
  src : @ffi.Float32Array,
  dst : @ffi.Uint16Array,
  len : Int,
) -> Unit =
  #| (src, dst, len) => {
  #|   for (let i = 0; i < len; i++) dst[i] = src[i]
  #| }

///|
extern "js" fn js_copy_f32_to_u32(
  src : @ffi.Float32Array,
  dst : @ffi.Uint32Array,
  len : Int,
) -> Unit =
  #| (src, dst, len) => {
  #|   for (let i = 0; i < len; i++) dst[i] = src[i]
  #| }

///|
fn as_uint32(data : @ffi.Float32Array) -> @ffi.Uint32Array {
  let len = data.length()
  let out = @ffi.Uint32Array::new(len)
  js_copy_f32_to_u32(data, out, len)
  out
}
