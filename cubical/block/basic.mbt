///|
/// Geometry source, independent of the game's block families.
pub(all) enum Geometry {
  Empty
  Procedural
  Gltf
}

///|
/// Render channels consumed by the world renderer.
pub(all) enum RenderPass {
  Opaque
  Tinted
  Liquid
  Translucent
}

///|
/// Engine-facing block description. Games supply models and resolved material
/// properties without exposing item categories or gameplay behavior.
pub(all) struct Block {
  name : @schema.UniqueID
  state : UInt
  occlusion_cull : Bool
  inter_cull : Bool
  luminance : Int
  opacity : Int
  geometry : Geometry
  model : @shape.Model
  tint : @util.Rgba
  render_pass : RenderPass
  selectable : Bool
  collision_boxes : (UInt) -> Array[@shape.Box]
  raycast_boxes : (UInt) -> Array[@shape.Box]
  outline_boxes : (UInt) -> Array[@shape.Box]
}

///|
pub(all) struct RenderBlock {
  block : Block
  faces : @shape.FaceLayerIndices
  internal_id : @schema.InternalID
}
