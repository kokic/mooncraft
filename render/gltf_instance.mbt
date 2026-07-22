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

///|
pub struct GltfMeshInstance {
  primitives : Array[GltfPrimitiveInstance]
}

///|
pub struct GltfMaterialInstance {
  name : String?
  texture : WebGLTexture
  has_texture : Bool
  factor_r : Float
  factor_g : Float
  factor_b : Float
  factor_a : Float
  alpha_mode : String
  alpha_cutoff : Float
  double_sided : Bool
}

///|
pub struct GltfEntityInstance {
  id : String
  nodes_len : Int
  roots : Array[Int]
  node_world : Array[Float32Array]
  model : Float32Array
  model_pos : Array[Double]
  model_rot : Array[Double]
  model_scale : Array[Double]
  base_model_rot : Array[Double]
  look_yaw : Float
  look_pitch : Float
  meshes : Array[GltfMeshInstance]
  materials : Array[GltfMaterialInstance]
  animations : Array[GltfAnimation]
  cur_anim_index : Int
  cur_anim_time : Float
  anim_looped : Bool
  default_tex_override : WebGLTexture?
  tex_overrides_by_index : Map[Int, WebGLTexture]
  tex_overrides_by_name : Map[String, WebGLTexture]
  white_texture : WebGLTexture
}
