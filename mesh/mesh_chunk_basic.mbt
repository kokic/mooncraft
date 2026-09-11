///|
pub fn build_chunk_mesh(
  registry : @block.RenderRegistry,
  chunk_data : Array[UInt],
  chunk_light : Bytes,
  size : Int,
) -> MeshData {
  guard PaddedChunk::new(registry, chunk_data, chunk_light, size) is Some(chunk) else {
    return MeshData::{
      positions: [],
      uvs: [],
      layers: [],
      colors: [],
      normals: [],
      count: 0,
    }
  }
  let arrays : MeshFaceArrays = {
    positions: [],
    uvs: [],
    layers: [],
    colors: [],
    normals: Some([]),
  }
  for x in 0..<size {
    for y in 0..<size {
      for z in 0..<size {
        let render_block = chunk.block(x, y, z)
        if render_block.block.shape is @block.Shape::Air {
          continue
        }
        emit_model_faces(chunk, arrays, render_block, x, y, z)
      }
    }
  }
  let normals = match arrays.normals {
    Some(normals) => normals
    None => []
  }
  MeshData::{
    positions: arrays.positions,
    uvs: arrays.uvs,
    layers: arrays.layers,
    colors: arrays.colors,
    normals,
    count: arrays.positions.length() / 3,
  }
}
