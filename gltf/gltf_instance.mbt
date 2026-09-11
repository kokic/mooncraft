///|
pub struct GltfProgramInfo {
  program : @webgl.WebGLProgram
  a_position : Int
  a_normal : Int
  a_uv : Int
  u_model : @webgl.WebGLUniformLocation
  u_view : @webgl.WebGLUniformLocation
  u_view_proj : @webgl.WebGLUniformLocation
  u_tex : @webgl.WebGLUniformLocation
  u_has_texture : @webgl.WebGLUniformLocation
  u_color : @webgl.WebGLUniformLocation
  u_alpha_mask : @webgl.WebGLUniformLocation
  u_alpha_cutoff : @webgl.WebGLUniformLocation
  u_fog_color : @webgl.WebGLUniformLocation
  u_fog_near : @webgl.WebGLUniformLocation
  u_fog_far : @webgl.WebGLUniformLocation
}

///|
pub struct GltfPrimitiveInstance {
  vao : @webgl.WebGLVertexArray
  pos_buf : @webgl.WebGLBuffer
  n_buf : @webgl.WebGLBuffer
  uv_buf : @webgl.WebGLBuffer
  index_buf : @webgl.WebGLBuffer?
  index_type : Int
  count : Int
  material_index : Int
  center_x : Float
  center_y : Float
  center_z : Float
}
