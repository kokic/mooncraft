///|
/// Build a single-block mesh for UI rendering.
pub fn build_ui_item_mesh(
  registry : BlockRegistry,
  long_id : UInt,
) -> MeshData {
  let data : Array[UInt] = [long_id]
  let light : Bytes = b""
  build_chunk_mesh(registry, data, light, 1)
}
