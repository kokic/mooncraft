///|

///|
/// JS-facing texture payload for UI rendering.
pub struct UiTexture {
  name : String
}

///|
/// JS-facing UI item payload (normalized for item-icons.js).
pub struct UiItemView {
  name : @util.UniqueName
  kind : String
  shape : String
  material : String
  category : String
  top : UiTexture
  side : UiTexture
  bottom : UiTexture
  texture : UiTexture
}

///|
fn is_torch_shape(shape : @block.Shape) -> Bool {
  shape is @block.Shape::Torch ||
  shape is @block.Shape::RedstoneTorch ||
  shape is @block.Shape::RedstoneTorchClassic
}

///|
fn shape_tag(shape : @block.Shape) -> String {
  if is_torch_shape(shape) {
    "torch"
  } else {
    "normal"
  }
}

///|
fn pick_side(faces : @block.TextureNames) -> String {
  match faces {
    { pos_x: Some(name), .. } => name
    { pos_z: Some(name), .. } => name
    { neg_x: Some(name), .. } => name
    { neg_z: Some(name), .. } => name
    { pos_y: Some(name), .. } => name
    { neg_y: Some(name), .. } => name
    _ => ""
  }
}

///|
fn texture_or_fallback(name : String) -> UiTexture {
  let tex = if name.length() > 0 { name } else { @block.fallback_texture }
  UiTexture::{ name: tex }
}

///|
fn category_tag(category : @item.Category) -> String {
  match category {
    @item.Block => "block"
    @item.Item => "item"
    @item.None => "none"
  }
}

///|
pub fn block_to_ui_item(block : @block.Block) -> UiItemView {
  let material_tag = if block.material is @block.Material::TintedLeaf {
    "tinted_leaf"
  } else {
    "normal"
  }
  let missing = texture_or_fallback("")
  if is_torch_shape(block.shape) {
    let tex = texture_or_fallback(block.faces.pos_x.unwrap_or(""))
    UiItemView::{
      name: block.name,
      shape: "torch",
      kind: "flat",
      material: material_tag,
      category: category_tag(block.category),
      top: missing,
      side: missing,
      bottom: missing,
      texture: tex,
    }
  } else {
    let faces = block.faces
    UiItemView::{
      name: block.name,
      shape: shape_tag(block.shape),
      kind: "block",
      material: material_tag,
      category: category_tag(block.category),
      top: texture_or_fallback(faces.pos_y.unwrap_or("")),
      side: texture_or_fallback(pick_side(faces)),
      bottom: texture_or_fallback(faces.neg_y.unwrap_or("")),
      texture: missing,
    }
  }
}

///|
pub fn item_to_ui_item(item : @item.Item) -> UiItemView {
  let missing = texture_or_fallback("")
  let tex = texture_or_fallback(item.texture)
  UiItemView::{
    name: item.name,
    shape: "normal",
    kind: "flat",
    material: "normal",
    category: category_tag(item.category),
    top: missing,
    side: missing,
    bottom: missing,
    texture: tex,
  }
}
