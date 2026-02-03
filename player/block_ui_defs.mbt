///|
pub struct UiItem {
  name : @util.UniqueName
  shape : String
  kind : String
  top : String
  side : String
  bottom : String
  texture : String
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
pub fn block_to_ui_def(block : @block.Block) -> UiItem {
  if is_torch_shape(block.shape) {
    let tex = block.faces.pos_x.unwrap_or("")
    UiItem::{
      name: block.name,
      shape: "torch",
      kind: "flat",
      top: "",
      side: "",
      bottom: "",
      texture: tex,
    }
  } else {
    let faces = block.faces
    UiItem::{
      name: block.name,
      shape: shape_tag(block.shape),
      kind: "block",
      top: faces.pos_y.unwrap_or(""),
      side: pick_side(faces),
      bottom: faces.neg_y.unwrap_or(""),
      texture: "",
    }
  }
}
