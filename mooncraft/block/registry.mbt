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
