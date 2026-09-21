///|
fn parse_nodes(root : Json) -> Array[GltfNode] {
  let definitions = json_array(json_field(json_object(root), "nodes"))
  definitions.map(definition => {
    let fields = json_object(definition)
    let identity = @camera.mat4_create()
    let matrix_json = json_field(fields, "matrix")
    let matrix = if json_array(matrix_json).length() == 16 {
      Some(json_float32_array(matrix_json, 16, identity))
    } else {
      None
    }
    {
      mesh: json_int(json_field(fields, "mesh"), fallback=-1),
      children: json_int_array(json_field(fields, "children")),
      translation: json_double_array(json_field(fields, "translation"), 3, [
        0.0, 0.0, 0.0,
      ]),
      rotation: json_double_array(json_field(fields, "rotation"), 4, [
        0.0, 0.0, 0.0, 1.0,
      ]),
      scale: json_double_array(json_field(fields, "scale"), 3, [1.0, 1.0, 1.0]),
      matrix,
    }
  })
}

///|
priv struct GltfMaterialMeta {
  name : String?
  texture_index : Int
  factor_r : Float
  factor_g : Float
  factor_b : Float
  factor_a : Float
  alpha_mode : String
  alpha_cutoff : Float
  double_sided : Bool
}

///|
/// Shared material metadata extraction (base color factor, alpha mode, etc.).
fn parse_material_meta(root : Json, index : Int) -> GltfMaterialMeta {
  let definitions = json_array(json_field(json_object(root), "materials"))
  guard definitions.get(index) is Some(definition) else {
    return GltfMaterialMeta::{
      name: None,
      texture_index: -1,
      factor_r: 1.0F,
      factor_g: 1.0F,
      factor_b: 1.0F,
      factor_a: 1.0F,
      alpha_mode: "OPAQUE",
      alpha_cutoff: 0.5F,
      double_sided: false,
    }
  }
  let fields = json_object(definition)
  let pbr = json_object(json_field(fields, "pbrMetallicRoughness"))
  let factor = json_double_array(json_field(pbr, "baseColorFactor"), 4, [
    1.0, 1.0, 1.0, 1.0,
  ])
  let texture_info = json_object(json_field(pbr, "baseColorTexture"))
  let name = match json_field(fields, "name") {
    String(value) => Some(value)
    _ => None
  }
  GltfMaterialMeta::{
    name,
    texture_index: json_int(json_field(texture_info, "index"), fallback=-1),
    factor_r: Float::from_double(factor[0]),
    factor_g: Float::from_double(factor[1]),
    factor_b: Float::from_double(factor[2]),
    factor_a: Float::from_double(factor[3]),
    alpha_mode: json_string(json_field(fields, "alphaMode"), fallback="OPAQUE"),
    alpha_cutoff: Float::from_double(
      json_double(json_field(fields, "alphaCutoff"), fallback=0.5),
    ),
    double_sided: json_bool(json_field(fields, "doubleSided")),
  }
}

///|
fn parse_roots(root : Json) -> Array[Int] {
  let root_json = json_object(root)
  let scenes = json_array(json_field(root_json, "scenes"))
  let scene_index = json_int(json_field(root_json, "scene"))
  guard scenes.get(scene_index) is Some(scene_json) else { [] }
  json_int_array(json_field(json_object(scene_json), "nodes"))
}

///|
fn GltfMaterialMeta::instantiate(
  self : GltfMaterialMeta,
  texture : @webgl.WebGLTexture,
) -> GltfMaterial {
  {
    name: self.name,
    texture_index: self.texture_index,
    texture,
    has_texture: false,
    factor_r: self.factor_r,
    factor_g: self.factor_g,
    factor_b: self.factor_b,
    factor_a: self.factor_a,
    alpha_mode: self.alpha_mode,
    alpha_cutoff: self.alpha_cutoff,
    double_sided: self.double_sided,
  }
}
