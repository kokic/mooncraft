///|
priv struct GltfNode {
  mesh : Int
  children : Array[Int]
  translation : Array[Double]
  rotation : Array[Double]
  scale : Array[Double]
  matrix : Float32Array?
}

///|
priv struct GltfMesh {
  primitives : Array[GltfPrimitiveInstance]
}

///|
priv struct GltfMaterial {
  name : String?
  texture_index : Int
  mut texture : WebGLTexture
  mut has_texture : Bool
  factor_r : Float
  factor_g : Float
  factor_b : Float
  factor_a : Float
  alpha_mode : String
  alpha_cutoff : Float
  double_sided : Bool
}

///|
priv struct GltfAnimationChannel {
  node : Int
  path : String
  interpolation : String
  input : Float32Array
  output : Float32Array
}

///|
priv struct GltfAnimation {
  name : String
  duration : Float
  channels : Array[GltfAnimationChannel]
}

///|
priv struct GltfAsset {
  nodes : Array[GltfNode]
  meshes : Array[GltfMesh]
  roots : Array[Int]
  materials : Array[GltfMaterial]
  animations : Array[GltfAnimation]
}

///|
enum GltfAssetSlot {
  Loading(Array[(GltfAsset) -> Unit])
  Ready(GltfAsset)
  Failed
}

///|
enum GltfTextureSlot {
  LoadingTexture(Array[(WebGLTexture) -> Unit])
  ReadyTexture(WebGLTexture)
  FailedTexture
}

///|
struct GltfInstance {
  id : String
  asset : GltfAsset
  model : Float32Array
  model_position : Array[Double]
  model_rotation : Array[Double]
  model_scale : Array[Double]
  base_model_rotation : Array[Double]
  node_local : Array[Float32Array]
  node_world : Array[Float32Array]
  mut animation_index : Int
  mut animation_time : Float
  animation_speed : Float
  animation_looped : Bool
  mut default_texture : WebGLTexture?
  texture_by_index : Map[Int, WebGLTexture]
  texture_by_name : Map[String, WebGLTexture]
}

///|
pub struct GltfRenderer {
  gl : WebGLRenderingContext
  program : GltfProgramInfo
  white_texture : WebGLTexture
  assets : Map[String, GltfAssetSlot]
  textures : Map[String, GltfTextureSlot]
  instances : Array[GltfInstance]
}
