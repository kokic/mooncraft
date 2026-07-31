///|
pub struct RenderBlock {
  block : Block
  faces : @shape.FaceLayerIndices
  internal_id : @schema.InternalID
}

///|
pub struct BlockRegistry[V] {
  by_name : Map[String, V]
  by_internal_id : Map[@schema.InternalID, V]
}

///|
pub fn[V] BlockRegistry::from_maps(
  by_name : Map[String, V],
  by_internal_id : Map[@schema.InternalID, V],
) -> BlockRegistry[V] {
  { by_name, by_internal_id }
}

///|
pub fn[V] BlockRegistry::get_by_name(
  self : BlockRegistry[V],
  name : String,
) -> V? {
  self.by_name.get(name)
}

///|
pub fn[V] BlockRegistry::get_by_internal_id(
  self : BlockRegistry[V],
  id : @schema.InternalID,
) -> V? {
  self.by_internal_id.get(id)
}

///|
pub fn BlockRegistry::name_to_internal_id(
  self : BlockRegistry[Block],
  name : String,
) -> @schema.InternalID {
  self
  .get_by_name(name)
  .map(block => block.internal_id())
  .unwrap_or(@schema.AIR_ID)
}

///|
let texture_index : Map[String, Int] = {
  let names = collect_texture_names()
  let idx : Map[String, Int] = Map([])
  for i in 0..<names.length() {
    idx[names[i]] = i
  }
  idx
}

///|
fn build_registries() -> (BlockRegistry[Block], BlockRegistry[RenderBlock]) {
  let block_by_name : Map[String, Block] = Map([])
  let block_by_id : Map[@schema.InternalID, Block] = Map([])
  let render_by_name : Map[String, RenderBlock] = Map([])
  let render_by_id : Map[@schema.InternalID, RenderBlock] = Map([])
  for def in blocks {
    block_by_name[def.name] = def
    block_by_id[def.internal_id()] = def
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
    render_by_name[def.name] = rb
    render_by_id[rb.internal_id] = rb
  }
  (
    BlockRegistry::{ by_name: block_by_name, by_internal_id: block_by_id },
    BlockRegistry::from_maps(render_by_name, render_by_id),
  )
}

///|
let registries : (BlockRegistry[Block], BlockRegistry[RenderBlock]) = build_registries()

///|
let block_registry : BlockRegistry[Block] = registries.0

///|
pub let render_registry : BlockRegistry[RenderBlock] = registries.1

///|
pub fn lookup_by_name(name : String) -> Block? {
  block_registry.get_by_name(name)
}

///|
pub fn lookup_by_internal_id(internal_id : @schema.InternalID) -> Block? {
  block_registry.get_by_internal_id(internal_id)
}

///|
pub fn name_to_internal_id(name : String) -> @schema.InternalID {
  block_registry.name_to_internal_id(name)
}
