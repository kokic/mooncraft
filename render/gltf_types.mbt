///|
pub struct GltfNode {
  mesh : Int
  children : Array[Int]
  translation : Array[Double]
  rotation : Array[Double]
  scale : Array[Double]
  has_matrix : Bool
  matrix : Float32Array
}

///|
pub struct GltfPrimitive {
  positions : Float32Array
  normals : Float32Array
  uvs : Float32Array
  indices : Float32Array?
  material_index : Int
  center_x : Float
  center_y : Float
  center_z : Float
}

///|
pub struct GltfMesh {
  primitives : Array[GltfPrimitive]
}

///|
pub struct GltfMaterial {
  name : String?
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
pub struct GltfAnimationChannel {
  node : Int
  path : String
  interpolation : String
  input : Float32Array
  output : Float32Array
}

///|
pub struct GltfAnimation {
  name : String
  duration : Float
  channels : Array[GltfAnimationChannel]
}

///|
pub struct GltfAsset {
  nodes : Array[GltfNode]
  meshes : Array[GltfMesh]
  roots : Array[Int]
  materials : Array[GltfMaterial]
  animations : Array[GltfAnimation]
}
