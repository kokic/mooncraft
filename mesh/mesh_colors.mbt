///|
pub fn build_chunk_colors_split(
  registry : @block.RenderRegistry,
  chunk_data : Array[UInt],
  chunk_light : Bytes,
  size : Int,
) -> MeshColorsSplit {
  guard PaddedChunk::new(registry, chunk_data, chunk_light, size) is Some(chunk) else {
    return MeshColorsSplit::{ normal: [], leaf: [], water: [], translucent: [] }
  }
  let targets = ColorTargets::new()
  for x in 0..<size {
    for y in 0..<size {
      for z in 0..<size {
        emit_split_block_colors(chunk, targets, x, y, z)
      }
    }
  }
  MeshColorsSplit::{
    normal: targets.normal,
    leaf: targets.leaf,
    water: targets.water,
    translucent: targets.translucent,
  }
}

///|
/// Emit one block's colors into its render bucket: baked glTF geometry or
/// procedural cube faces.
fn emit_split_block_colors(
  chunk : PaddedChunk,
  targets : ColorTargets,
  x : Int,
  y : Int,
  z : Int,
) -> Unit {
  let render_block = chunk.block(x, y, z)
  if render_block.block.shape is @block.Shape::Air {
    return
  }
  let target = targets.for_block(render_block)
  if render_block.block.shape is @block.Shape::Gltf {
    guard @gltf.block_gltf_model(render_block.block.name) is Some(model) else {
      return
    }
    let light_scale = @util.light_level_scale(chunk.light(x, y, z))
    emit_gltf_colors_into(model, light_scale, target)
    return
  }
  emit_face_colors(chunk, target, render_block, x, y, z)
}

///|
/// Build only per-vertex colors for a chunk mesh (same vertex order as build_chunk_mesh).
pub fn build_chunk_colors(
  registry : @block.RenderRegistry,
  chunk_data : Array[UInt],
  chunk_light : Bytes,
  size : Int,
) -> Array[Float] {
  guard PaddedChunk::new(registry, chunk_data, chunk_light, size) is Some(chunk) else {
    return []
  }
  let colors : Array[Float] = []
  for x in 0..<size {
    for y in 0..<size {
      for z in 0..<size {
        let render_block = chunk.block(x, y, z)
        if render_block.block.shape is @block.Shape::Air {
          continue
        }
        emit_face_colors(chunk, colors, render_block, x, y, z)
      }
    }
  }
  colors
}
