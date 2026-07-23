///|
pub fn dispose_gltf_primitives(
  gl : WebGLRenderingContext,
  prims : Array[GltfPrimitiveInstance],
) -> Unit {
  for prim in prims {
    gl.delete_vertex_array(prim.vao)
    gl.delete_buffer(prim.pos_buf)
    gl.delete_buffer(prim.n_buf)
    gl.delete_buffer(prim.uv_buf)
    match prim.index_buf {
      Some(buf) => gl.delete_buffer(buf)
      None => ()
    }
  }
}
