///|
pub struct RenderBlock {
  block : @block.Block
  faces : @shape.FaceLayerIndices
  internal_id : @schema.InternalID
}

///|
pub struct BlockRegistry {
  by_name : Map[String, RenderBlock]
  by_internal_id : Map[@schema.InternalID, RenderBlock]
}

///|
pub fn BlockRegistry::create(
  texture_names : Array[String],
  texture_indices : Array[Int],
) -> BlockRegistry {
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
  let blocks_by_name : Map[String, RenderBlock] = Map([])
  let blocks_by_internal_id : Map[@schema.InternalID, RenderBlock] = Map([])
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
    let internal_id = def.internal_id()
    let block = RenderBlock::{ block: def, faces, internal_id }
    blocks_by_name[def.name] = block
    blocks_by_internal_id[internal_id] = block
  }
  BlockRegistry::{ by_name: blocks_by_name, by_internal_id: blocks_by_internal_id }
}

///|
pub fn BlockRegistry::get_by_name(
  registry : BlockRegistry,
  name : String,
) -> RenderBlock? {
  registry.by_name.get(name)
}

///|
pub fn BlockRegistry::get_by_internal_id(
  registry : BlockRegistry,
  internal_id : @schema.InternalID,
) -> RenderBlock? {
  registry.by_internal_id.get(internal_id)
}
