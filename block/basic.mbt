///|
/// Block definition used by both simulation and rendering.
/// Rendering derives texture indices from `faces`.
pub struct Block {
  name : @util.UniqueName
  id : BlockId
  state : UInt
  occlusion_cull : Bool
  /// Eliminate coplanarity between adjacent blocks
  inter_cull : Bool
  /// [0, 15]
  luminance : Int
  /// [0, 15]
  opacity : Int
  alpha_mode : AlphaMode
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
  occlusion_cull? : Bool = true,
  same_block_cull? : Bool = true,
  luminance? : Int = 0,
  opacity? : Int = 15,
  alpha_mode? : AlphaMode = AlphaMode::Opaque,
  shape? : Shape = Shape::Cube,
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
    occlusion_cull,
    inter_cull: same_block_cull,
    luminance,
    opacity,
    alpha_mode,
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

///|
/// True if the block should be selectable (outlined) in UI.
pub fn Block::is_selectable(block : Block) -> Bool {
  match block.shape {
    Air => false
    _ => true
  }
}

///|
pub let fallback_texture : String = "missing_tile"

///|
pub fn collect_texture_names() -> Array[String] {
  let seen : Map[String, Bool] = Map::new()
  let out : Array[String] = [fallback_texture]
  seen[fallback_texture] = true
  for block in blocks {
    let faces = block.faces
    if faces.pos_x is Some(tex) && !seen.contains(tex) {
      seen[tex] = true
      out.push(tex)
    }
    if faces.neg_x is Some(tex) && !seen.contains(tex) {
      seen[tex] = true
      out.push(tex)
    }
    if faces.pos_y is Some(tex) && !seen.contains(tex) {
      seen[tex] = true
      out.push(tex)
    }
    if faces.neg_y is Some(tex) && !seen.contains(tex) {
      seen[tex] = true
      out.push(tex)
    }
    if faces.pos_z is Some(tex) && !seen.contains(tex) {
      seen[tex] = true
      out.push(tex)
    }
    if faces.neg_z is Some(tex) && !seen.contains(tex) {
      seen[tex] = true
      out.push(tex)
    }
  }
  for item in @item.items {
    let tex = item.texture
    if tex.length() > 0 && !seen.contains(tex) {
      seen[tex] = true
      out.push(tex)
    }
  }
  out
}

///|
/// Collect (long_id, opacity, luminance) for lighting.
pub fn collect_block_light_info() -> Array[Array[Int]] {
  let out : Array[Array[Int]] = []
  for block in blocks {
    let long_id = block.long_id().reinterpret_as_int()
    out.push([long_id, block.opacity, block.luminance])
  }
  out
}
