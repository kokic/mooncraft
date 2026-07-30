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
pub fn BlockRegistry::create() -> BlockRegistry[Block] {
  let by_name : Map[String, Block] = Map([])
  let by_internal_id : Map[@schema.InternalID, Block] = Map([])
  for block in blocks {
    by_name[block.name] = block
    by_internal_id[block.internal_id()] = block
  }
  BlockRegistry::{ by_name, by_internal_id }
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
let registry : BlockRegistry[Block] = BlockRegistry::create()

///|
pub fn lookup_by_name(name : String) -> Block? {
  registry.get_by_name(name)
}

///|
pub fn lookup_by_internal_id(internal_id : @schema.InternalID) -> Block? {
  registry.get_by_internal_id(internal_id)
}

///|
pub fn name_to_internal_id(name : String) -> @schema.InternalID {
  registry.name_to_internal_id(name)
}
