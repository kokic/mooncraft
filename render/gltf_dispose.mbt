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

///|
pub fn dispose_gltf_meshes(
  gl : WebGLRenderingContext,
  meshes : Array[GltfMeshInstance],
) -> Unit {
  for mesh in meshes {
    dispose_gltf_primitives(gl, mesh.primitives)
  }
}

///|
pub fn dispose_gltf_textures(
  gl : WebGLRenderingContext,
  textures : Array[WebGLTexture],
) -> Unit {
  for tex in textures {
    gl.delete_texture(tex)
  }
}
