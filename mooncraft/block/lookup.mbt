///|
let texture_index : @hashmap.HashMap[String, Int] = {
  let names = collect_texture_names()
  let idx : @hashmap.HashMap[String, Int] = @hashmap.HashMap([])
  for i in 0..<names.length() {
    idx[names[i]] = i
  }
  idx
}

///|
fn build_registries() -> (BlockRegistry[Block], BlockRegistry[RenderBlock]) {
  let block_by_name : @hashmap.HashMap[String, Block] = @hashmap.HashMap([])
  let block_by_id : @hashmap.HashMap[@schema.InternalID, Block] = @hashmap.HashMap([],
  )
  let render_by_name : @hashmap.HashMap[String, RenderBlock] = @hashmap.HashMap([],
  )
  let render_by_id : @hashmap.HashMap[@schema.InternalID, RenderBlock] = @hashmap.HashMap([],
  )
  for def in blocks {
    block_by_name[def.name] = def
    block_by_id[def.internal_id()] = def
    let resolve_layer = (tex_name : String?) => {
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
    let rb = RenderBlock::{
      block: def.engine_block(),
      faces,
      internal_id: def.internal_id(),
    }
    render_by_name[def.name] = rb
    render_by_id[rb.internal_id] = rb
  }
  (
    BlockRegistry::from_maps(block_by_name, block_by_id),
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
  block_registry
  .get_by_name(name)
  .map(block => block.internal_id())
  .unwrap_or(@schema.AIR_ID)
}
