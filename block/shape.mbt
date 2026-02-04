///|
pub enum Shape {
  Air
  Cube
  Log
  GrassPath
  Cactus
  Torch
  RedstoneTorch
  RedstoneTorchClassic
}

///|
pub fn Shape::is_torch_genus(shape : Shape) -> Bool {
  match shape {
    Torch | RedstoneTorch | RedstoneTorchClassic => true
    _ => false
  }
}

///|
fn Shape::model(shape : Shape) -> @shape.Model {
  match shape {
    Shape::GrassPath => @genus.grass_path_model
    Shape::Cactus => @genus.cactus_model
    Shape::Log => @genus.log_model
    Shape::Torch => @genus.torch_model
    Shape::RedstoneTorch => @genus.redstone_torch_model
    Shape::RedstoneTorchClassic => @genus.redstone_torch_classic_model
    _ => @genus.default_model
  }
}
