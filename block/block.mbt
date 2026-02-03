///|
/// Block definition used by both simulation and rendering.
/// Rendering derives texture indices from `faces`.
pub struct Block {
  name : @util.UniqueName
  id : BlockId
  state : UInt
  opacity : Int
  luminance : Int
  shape : Shape
  material : Material
  category : @item.Category
  faces : TextureNames
}

///|
pub type BlockId = UInt

///|
fn Block::create(
  name : @util.UniqueName,
  id? : BlockId = alloc_id(),
  state? : UInt = 0,
  opacity? : Int = 15,
  luminance? : Int = 0,
  shape? : Shape = Shape::Normal,
  material? : Material = Material::Normal,
  category? : @item.Category = @item.Block,
  faces : FixedArray[String],
) -> Block {
  let faces = match faces.length() {
    0 => TextureNames::new()
    1 => TextureNames::isotropic(faces[0])
    2 => TextureNames::axial(faces[0], faces[1])
    3 => TextureNames::top_bottom(faces[0], faces[1], faces[2])
    _ => panic()
  }
  Block::{
    name,
    id,
    state,
    opacity,
    luminance,
    shape,
    material,
    category,
    faces,
  }
}

///|
pub fn Block::long_id(block : Block, state? : UInt = block.state) -> UInt {
  @util.pack_long_id(block.id, state)
}
