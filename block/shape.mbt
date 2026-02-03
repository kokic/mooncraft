///|
pub enum Shape {
  Air
  Normal
  Torch
  RedstoneTorch
  RedstoneTorchClassic
}

///|
pub fn Shape::occludes_faces(shape : Shape, material : Material) -> Bool {
  if material is Material::TintedLeaf {
    false
  } else {
    match shape {
      Shape::Air => false
      Shape::Normal => true
      Shape::Torch
      | Shape::RedstoneTorch
      | Shape::RedstoneTorchClassic => false
    }
  }
}

///|
pub fn Shape::is_torch_genus(shape : Shape) -> Bool {
  match shape {
    Torch | RedstoneTorch | RedstoneTorchClassic => true
    _ => false
  }
}
