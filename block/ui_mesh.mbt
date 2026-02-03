///|
/// Build a single-block mesh for UI rendering.
pub fn build_ui_item_mesh(registry : BlockRegistry, long_id : UInt) -> MeshData {
  let data : Array[UInt] = [long_id]
  let light : Bytes = b""
  let mesh = build_chunk_mesh(registry, data, light, 1)
  let positions : Array[Float] = []
  for i in 0..<(mesh.positions.length() / 3) {
    let x = mesh.positions[i * 3] - 0.5F
    let y = mesh.positions[i * 3 + 1] - 0.5F
    let z = mesh.positions[i * 3 + 2] - 0.5F
    positions.push(x)
    positions.push(y)
    positions.push(z)
  }
  MeshData::{
    positions,
    uvs: mesh.uvs,
    layers: mesh.layers,
    colors: mesh.colors,
    normals: mesh.normals,
    count: mesh.count,
  }
}
