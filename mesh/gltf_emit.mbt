///|
/// Merge baked glTF geometry (route A) into the same chunk mesh buffers that
/// procedural block faces use. Positions are model-space [0,1] and get the
/// block offset added; colors fold in the baked dominant-axis shade, the block
/// light level, and the material base color factor.
pub fn emit_gltf_block_into(
  model : @gltf.GltfBakedModel,
  ox : Float,
  oy : Float,
  oz : Float,
  layer_f : Float,
  light_scale : Float,
  positions : Array[Float],
  uvs : Array[Float],
  layers : Array[Float],
  colors : Array[Float],
) -> Unit {
  for primitive in model.primitives {
    let primitive_positions = primitive.positions
    let primitive_uvs = primitive.uvs
    for t in 0..<(primitive_positions.length() / 9) {
      let shade = primitive.shades[t]
      let color_scale = shade * light_scale
      for k in 0..<3 {
        let base = t * 9 + k * 3
        positions.push(primitive_positions[base] + ox)
        positions.push(primitive_positions[base + 1] + oy)
        positions.push(primitive_positions[base + 2] + oz)
        let ubase = t * 6 + k * 2
        uvs.push(primitive_uvs[ubase])
        uvs.push(primitive_uvs[ubase + 1])
        layers.push(layer_f)
        colors.push(color_scale * primitive.factor_r)
        colors.push(color_scale * primitive.factor_g)
        colors.push(color_scale * primitive.factor_b)
        colors.push(primitive.factor_a)
      }
    }
  }
}

///|
/// Recompute only per-vertex colors for baked glTF geometry, in the same
/// vertex order as `emit_gltf_block_into`.
pub fn emit_gltf_colors_into(
  model : @gltf.GltfBakedModel,
  light_scale : Float,
  colors : Array[Float],
) -> Unit {
  for primitive in model.primitives {
    for t in 0..<(primitive.positions.length() / 9) {
      let shade = primitive.shades[t]
      let color_scale = shade * light_scale
      for _ in 0..<3 {
        colors.push(color_scale * primitive.factor_r)
        colors.push(color_scale * primitive.factor_g)
        colors.push(color_scale * primitive.factor_b)
        colors.push(primitive.factor_a)
      }
    }
  }
}
