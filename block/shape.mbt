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
fn Shape::double_sided(shape : Shape) -> Bool {
  match shape {
    Cactus => true
    _ => false
  }
}

///|
fn box_for_shape(
  shape : Shape,
) -> ((Float, Float, Float), (Float, Float, Float))? {
  match shape {
    Shape::GrassPath =>
      Some(((0.0F, 0.0F, 0.0F), (1.0F, @genus.GRASS_PATH_MAX_Y, 1.0F)))
    Shape::Cactus =>
      Some(
        (
          (@genus.CACTUS_MIN, 0.0F, @genus.CACTUS_MIN),
          (@genus.CACTUS_MAX, 1.0F, @genus.CACTUS_MAX),
        ),
      )
    _ => None
  }
}

///|
fn box_for_shape_face(
  shape : Shape,
  face : FaceName,
) -> ((Float, Float, Float), (Float, Float, Float))? {
  match shape {
    Shape::Cactus => {
      let u0 = @genus.CACTUS_MIN
      let u1 = @genus.CACTUS_MAX
      match face {
        FaceName::PosX =>
          Some(((u1, 0.0F, 0.0F), (u1, 1.0F, 1.0F)))
        FaceName::NegX =>
          Some(((u0, 0.0F, 0.0F), (u0, 1.0F, 1.0F)))
        FaceName::PosZ =>
          Some(((0.0F, 0.0F, u1), (1.0F, 1.0F, u1)))
        FaceName::NegZ =>
          Some(((0.0F, 0.0F, u0), (1.0F, 1.0F, u0)))
        FaceName::PosY | FaceName::NegY =>
          Some(((u0, 0.0F, u0), (u1, 1.0F, u1)))
      }
    }
    _ => box_for_shape(shape)
  }
}
