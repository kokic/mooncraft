///|
pub fn build_chunk_mesh_split(
  registry : @block.RenderRegistry,
  chunk_data : Array[UInt],
  chunk_light : Bytes,
  size : Int,
) -> MeshSplit {
  guard PaddedChunk::new(registry, chunk_data, chunk_light, size) is Some(chunk) else {
    return MeshSplitTargets::new().into_mesh_split()
  }
  let targets = MeshSplitTargets::new()
  for x in 0..<size {
    for y in 0..<size {
      for z in 0..<size {
        emit_split_block_mesh(chunk, targets, x, y, z)
      }
    }
  }
  targets.into_mesh_split()
}

///|
/// Emit one block into its render bucket: baked glTF geometry or procedural
/// cube faces.
fn emit_split_block_mesh(
  chunk : PaddedChunk,
  targets : MeshSplitTargets,
  x : Int,
  y : Int,
  z : Int,
) -> Unit {
  let render_block = chunk.block(x, y, z)
  if render_block.block.shape is @block.Shape::Air {
    return
  }
  let arrays = targets.for_block(render_block)
  if render_block.block.shape is @block.Shape::Gltf {
    guard @gltf.block_gltf_model(render_block.block.name) is Some(model) else {
      return
    }
    let light_scale = @util.light_level_scale(chunk.light(x, y, z))
    emit_gltf_block_into(
      model,
      Float::from_int(x),
      Float::from_int(y),
      Float::from_int(z),
      Float::from_int(render_block.faces.pos_x),
      light_scale,
      arrays.positions,
      arrays.uvs,
      arrays.layers,
      arrays.colors,
    )
    return
  }
  emit_model_faces(chunk, arrays, render_block, x, y, z)
}
