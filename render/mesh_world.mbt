///|
pub fn build_world_mesh(
  registry : RenderRegistry,
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
  registry : RenderRegistry,
  entries : Array[ChunkEntry],
  size : Int,
) -> MeshSplit {
  if entries.length() == 1 {
    let entry = entries[0]
    let mesh = build_chunk_mesh_split(registry, entry.data, entry.light, size)
    let offset_x = Float::from_int(entry.x * size)
    let offset_y = Float::from_int(entry.y * size)
    let offset_z = Float::from_int(entry.z * size)
    for part in [mesh.normal, mesh.leaf, mesh.water, mesh.translucent] {
      for i in 0..<part.count {
        let index = i * 3
        part.positions[index] = part.positions[index] + offset_x
        part.positions[index + 1] = part.positions[index + 1] + offset_y
        part.positions[index + 2] = part.positions[index + 2] + offset_z
      }
    }
    return mesh
  }
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
