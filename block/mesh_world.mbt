///|
pub fn build_world_mesh(
  registry : BlockRegistry,
  entries : Array[ChunkEntry],
  size : Int,
) -> MeshData {
  let out = MeshDataBuffer::new()
  for entry in entries {
    let mesh = build_chunk_mesh(registry, entry.data, entry.light, size)
    let offset_x = Float::from_int(entry.x * size)
    let offset_y = Float::from_int(entry.y * size)
    let offset_z = Float::from_int(entry.z * size)
    out.append_with_offset(mesh, offset_x, offset_y, offset_z)
  }
  out.to_mesh_data()
}

///|
pub fn build_world_mesh_split(
  registry : BlockRegistry,
  entries : Array[ChunkEntry],
  size : Int,
) -> MeshSplit {
  let normal = MeshDataBuffer::new()
  let leaf = MeshDataBuffer::new()
  let water = MeshDataBuffer::new()
  let translucent = MeshDataBuffer::new()
  for entry in entries {
    let mesh = build_chunk_mesh_split(registry, entry.data, entry.light, size)
    let offset_x = Float::from_int(entry.x * size)
    let offset_y = Float::from_int(entry.y * size)
    let offset_z = Float::from_int(entry.z * size)
    normal.append_with_offset(mesh.normal, offset_x, offset_y, offset_z)
    leaf.append_with_offset(mesh.leaf, offset_x, offset_y, offset_z)
    water.append_with_offset(mesh.water, offset_x, offset_y, offset_z)
    translucent.append_with_offset(
      mesh.translucent,
      offset_x,
      offset_y,
      offset_z,
    )
  }
  MeshSplit::{
    normal: normal.to_mesh_data(),
    leaf: leaf.to_mesh_data(),
    water: water.to_mesh_data(),
    translucent: translucent.to_mesh_data(),
  }
}
