///|
#warnings("-unused_constructor")
pub enum Shape {
  Air
  Cube
  GrassPath
  Slab
  VerticalSlab
  Liquid
  Cactus
  Torch
  RedstoneTorch
  RedstoneTorchClassic
  /// Render shape whose geometry comes from a baked glTF model.
  Gltf
}

///|
pub(all) enum RaycastMode {
  Skip
  Bounds
  LiquidBounds
}

///|
pub type PlacementState = (
  UInt,
  Array[Int],
  Array[Int],
  Array[Double],
  (Float, Float, Float),
) -> UInt

///|
/// All behavior a block family contributes outside of its registry metadata.
/// Keep a new family's render, collision, targeting, and placement rules here.
pub(all) struct BlockProfile {
  model : @shape.Model
  collision_boxes : (UInt) -> Array[@shape.Box]
  raycast_boxes : (UInt) -> Array[@shape.Box]
  outline_boxes : (UInt) -> Array[@shape.Box]
  selectable : Bool
  raycast_mode : RaycastMode
  placement_state : PlacementState
}

///|
fn Block::profile(block : Block) -> BlockProfile {
  profile_by_block(block)
}

///|
pub fn model_by_block(block : Block) -> @shape.Model {
  block.profile().model
}

///|
pub fn Block::collision_boxes(block : Block) -> Array[@shape.Box] {
  (block.profile().collision_boxes)(block.state)
}

///|
pub fn Block::is_selectable(block : Block) -> Bool {
  block.profile().selectable
}

///|
pub fn Block::outline_boxes(block : Block) -> Array[@shape.Box] {
  (block.profile().outline_boxes)(block.state)
}

///|
pub fn get_shape_desc(internal_id : @schema.InternalID) -> @shape.Source? {
  lookup_by_internal_id(internal_id).map(block => @shape.Source::{
    boxes: block.collision_boxes(),
    facing: -1,
  })
}

///|
pub fn get_outline_desc(internal_id : @schema.InternalID) -> @shape.Source? {
  lookup_by_internal_id(internal_id).map(block => @shape.Source::{
    boxes: block.outline_boxes(),
    facing: -1,
  })
}
