///|
pub struct RenderBlock {
  block : @block.Block
  faces : @shape.FaceLayerIndices
  internal_id : @schema.InternalID
}

///|
pub type RenderRegistry = @block.BlockRegistry[RenderBlock]

///|
/// Concrete wrapper for FFI; delegates to the generic method.
pub fn get_render_block_by_internal_id(
  registry : RenderRegistry,
  id : @schema.InternalID,
) -> RenderBlock? {
  @block.BlockRegistry::get_by_internal_id(registry, id)
}

///|
pub fn RenderBlock::create_registry(
  texture_names : Array[String],
  texture_indices : Array[Int],
) -> RenderRegistry {
  let texture_index : Map[String, Int] = Map([])
  let len = if texture_names.length() < texture_indices.length() {
    texture_names.length()
  } else {
    texture_indices.length()
  }
  for i in 0..<len {
    let name = texture_names[i]
    let index = texture_indices[i]
    if name.length() > 0 {
      texture_index[name] = index
    }
  }
  let by_name : Map[String, RenderBlock] = Map([])
  let by_internal_id : Map[@schema.InternalID, RenderBlock] = Map([])
  for def in @block.blocks {
    let resolve_layer = fn(tex_name : String?) -> Int {
      tex_name.bind(name => texture_index.get(name)).unwrap_or(0)
    }
    let faces = @shape.FaceLayerIndices::{
      pos_x: resolve_layer(def.faces.pos_x),
      neg_x: resolve_layer(def.faces.neg_x),
      pos_y: resolve_layer(def.faces.pos_y),
      neg_y: resolve_layer(def.faces.neg_y),
      pos_z: resolve_layer(def.faces.pos_z),
      neg_z: resolve_layer(def.faces.neg_z),
    }
    let rb = RenderBlock::{ block: def, faces, internal_id: def.internal_id() }
    by_name[def.name] = rb
    by_internal_id[rb.internal_id] = rb
  }
  @block.BlockRegistry::from_maps(by_name, by_internal_id)
}
