///|
/// Block definition used by both simulation and rendering.
/// Rendering derives texture indices from `faces`.
pub struct Block {
  name : @schema.UniqueID
  priv id : BlockId
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
  facing : Facing
  material : Material
  category : @item.Category
  faces : TextureNames
}

///|
pub type BlockId = UInt

///|
let block_id_table : @schema.InternalIDCounter = @schema.InternalIDCounter::new()

///|
fn alloc_block_id() -> @schema.InternalID {
  block_id_table.allocate()
}

///|
fn Block::create(
  name : @schema.UniqueID,
  state? : UInt = 0,
  occlusion_cull? : Bool = true,
  same_block_cull? : Bool = true,
  luminance? : Int = 0,
  opacity? : Int = 15,
  alpha_mode? : AlphaMode = AlphaMode::Opaque,
  shape? : Shape = Shape::Cube,
  facing? : Facing = Facing::None,
  material? : Material = Material::Normal,
  category? : @item.Category = @item.Block,
  faces : FixedArray[String],
) -> Block {
  Block::unsafe_create_with_specified_id(
    name,
    state~,
    occlusion_cull~,
    same_block_cull~,
    luminance~,
    opacity~,
    alpha_mode~,
    shape~,
    facing~,
    material~,
    category~,
    faces,
    alloc_block_id(),
  )
}

///|
fn Block::unsafe_create_with_specified_id(
  name : @schema.UniqueID,
  state? : UInt = 0,
  occlusion_cull? : Bool = true,
  same_block_cull? : Bool = true,
  luminance? : Int = 0,
  opacity? : Int = 15,
  alpha_mode? : AlphaMode = AlphaMode::Opaque,
  shape? : Shape = Shape::Cube,
  facing? : Facing = Facing::None,
  material? : Material = Material::Normal,
  category? : @item.Category = @item.Block,
  faces : FixedArray[String],
  id : BlockId,
) -> Block {
  let faces = match faces.length() {
    0 => TextureNames::new()
    1 => TextureNames::isotropic(faces[0])
    2 => TextureNames::axial(faces[0], faces[1])
    3 => TextureNames::top_bottom(faces[0], faces[1], faces[2])
    6 =>
      TextureNames::new(
        pos_x=faces[0],
        neg_x=faces[1],
        pos_y=faces[2],
        neg_y=faces[3],
        pos_z=faces[4],
        neg_z=faces[5],
      )
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
    facing,
    material,
    category,
    faces,
  }
}

///|
pub fn Block::internal_id(
  block : Block,
  state? : UInt = block.state,
) -> @schema.InternalID {
  @schema.encode_variant(block.id, state)
}

///|
pub let fallback_texture : String = "missing_tile"

///|
pub fn collect_texture_names() -> Array[String] {
  let seen : Map[String, Bool] = Map([])
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
/// Collect (internal_id, opacity, luminance) for lighting.
pub fn collect_block_light_info() -> Array[Array[Int]] {
  let out : Array[Array[Int]] = []
  for block in blocks {
    let internal_id = block.internal_id().reinterpret_as_int()
    out.push([internal_id, block.opacity, block.luminance])
  }
  out
}
