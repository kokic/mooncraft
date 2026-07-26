///|
pub(all) struct ChunkEntry {
  x : Int
  y : Int
  z : Int
  data : Array[UInt]
  light : Bytes
}

///|
pub struct MeshData {
  positions : Array[Float]
  uvs : Array[Float]
  layers : Array[Float]
  colors : Array[Float]
  normals : Array[Float]
  count : Int
}

///|
pub struct MeshSplit {
  normal : MeshData
  leaf : MeshData
  water : MeshData
  translucent : MeshData
}

///|
pub struct MeshColorsSplit {
  normal : Array[Float]
  leaf : Array[Float]
  water : Array[Float]
  translucent : Array[Float]
}

///|
priv struct MeshDataBuffer {
  positions : Array[Float]
  uvs : Array[Float]
  layers : Array[Float]
  colors : Array[Float]
  normals : Array[Float]
}

///|
fn MeshDataBuffer::new() -> MeshDataBuffer {
  MeshDataBuffer::{
    positions: [],
    uvs: [],
    layers: [],
    colors: [],
    normals: [],
  }
}

///|
fn MeshDataBuffer::append_with_offset(
  self : MeshDataBuffer,
  mesh : MeshData,
  offset_x : Float,
  offset_y : Float,
  offset_z : Float,
) -> Unit {
  for i in 0..<mesh.count {
    let pidx = i * 3
    self.positions.push(mesh.positions[pidx] + offset_x)
    self.positions.push(mesh.positions[pidx + 1] + offset_y)
    self.positions.push(mesh.positions[pidx + 2] + offset_z)
    let uidx = i * 2
    self.uvs.push(mesh.uvs[uidx])
    self.uvs.push(mesh.uvs[uidx + 1])
    self.layers.push(mesh.layers[i])
    let cidx = i * 4
    self.colors.push(mesh.colors[cidx])
    self.colors.push(mesh.colors[cidx + 1])
    self.colors.push(mesh.colors[cidx + 2])
    self.colors.push(mesh.colors[cidx + 3])
    if mesh.normals.length() == mesh.count * 3 {
      let nidx = i * 3
      self.normals.push(mesh.normals[nidx])
      self.normals.push(mesh.normals[nidx + 1])
      self.normals.push(mesh.normals[nidx + 2])
    }
  }
}

///|
fn MeshDataBuffer::to_mesh_data(self : MeshDataBuffer) -> MeshData {
  MeshData::{
    positions: self.positions,
    uvs: self.uvs,
    layers: self.layers,
    colors: self.colors,
    normals: self.normals,
    count: self.positions.length() / 3,
  }
}
