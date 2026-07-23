///|
pub struct GltfProgramInfo {
  program : WebGLProgram
  a_position : Int
  a_normal : Int
  a_uv : Int
  u_model : WebGLUniformLocation
  u_view : WebGLUniformLocation
  u_view_proj : WebGLUniformLocation
  u_tex : WebGLUniformLocation
  u_has_texture : WebGLUniformLocation
  u_color : WebGLUniformLocation
  u_alpha_mask : WebGLUniformLocation
  u_alpha_cutoff : WebGLUniformLocation
  u_fog_color : WebGLUniformLocation
  u_fog_near : WebGLUniformLocation
  u_fog_far : WebGLUniformLocation
}

///|
pub struct GltfPrimitiveInstance {
  vao : WebGLVertexArray
  pos_buf : WebGLBuffer
  n_buf : WebGLBuffer
  uv_buf : WebGLBuffer
  index_buf : WebGLBuffer?
  index_type : Int
  count : Int
  material_index : Int
  center_x : Float
  center_y : Float
  center_z : Float
}
