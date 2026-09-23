///|
pub struct BlockRegistry[V] {
  by_name : @hashmap.HashMap[String, V]
  by_internal_id : @hashmap.HashMap[@schema.InternalID, V]
}

///|
pub fn[V] BlockRegistry::from_maps(
  by_name : @hashmap.HashMap[String, V],
  by_internal_id : @hashmap.HashMap[@schema.InternalID, V],
) -> BlockRegistry[V] {
  { by_name, by_internal_id, }
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
pub type RenderRegistry = BlockRegistry[RenderBlock]

///|
/// Concrete wrapper for FFI; delegates to the generic method.
pub fn get_render_block_by_internal_id(
  registry : RenderRegistry,
  id : @schema.InternalID,
) -> RenderBlock? {
  registry.get_by_internal_id(id)
}
