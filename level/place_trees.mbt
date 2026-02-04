///|
pub struct TreePlacementParams {
  /// Noise frequency controlling density variation scale. 
  /// higher => faster changes over space.
  freq : Double
  /// Density threshold; higher => fewer trees.
  threshold : Double
  /// Minimum spacing between candidate placements (cell size in blocks).
  min_spacing : Int
}

///|
/// Default oak tree density for plains.
pub let plains_oak_params : TreePlacementParams = TreePlacementParams::{
  freq: 0.09, // 0.8 ~ 1
  threshold: 0.4, // 0.3 ~ 0.5
  min_spacing: 6,
}

///|
fn sample_oak_cell_offset(
  noise : @util.PerlinNoise,
  cell_x : Int,
  cell_z : Int,
  freq : Double,
  spacing : Int,
) -> (Int, Int) {
  let fx = cell_x.to_double() * freq
  let fz = cell_z.to_double() * freq
  let ox = noise.gen2d(fx + 31.7, fz - 17.3)
  let oz = noise.gen2d(fx - 13.1, fz + 29.9)
  let max_offset = spacing - 1
  let offset_x = ((ox + 1.0) * 0.5 * max_offset.to_double()).round().to_int()
  let offset_z = ((oz + 1.0) * 0.5 * max_offset.to_double()).round().to_int()
  (offset_x, offset_z)
}

///|
pub fn should_place_oak(
  noise : @util.PerlinNoise,
  wx : Int,
  wz : Int,
  params : TreePlacementParams,
) -> Bool {
  if params.min_spacing <= 1 {
    noise.gen2d(wx.to_double() * params.freq, wz.to_double() * params.freq) >
    params.threshold
  } else {
    let cell_x = @util.floor_div(wx, params.min_spacing)
    let cell_z = @util.floor_div(wz, params.min_spacing)
    let density = noise.gen2d(
      wx.to_double() * params.freq,
      wz.to_double() * params.freq,
    )
    if density <= params.threshold {
      false
    } else {
      let (ox, oz) = sample_oak_cell_offset(
        noise,
        cell_x,
        cell_z,
        params.freq * 2.0,
        params.min_spacing,
      )
      let target_x = cell_x * params.min_spacing + ox
      let target_z = cell_z * params.min_spacing + oz
      wx == target_x && wz == target_z
    }
  }
}

///|
pub fn place_oak_trees_in_chunk(
  world : World,
  chunk : Chunk,
  params? : TreePlacementParams = plains_oak_params,
  is_grass? : (UInt) -> Bool = long_id => long_id ==
    @block.lookup_by_name("grass").unwrap().id,
) -> Unit {
  apply_pending_to_chunk(chunk)
  let region = ChunkRegion::new(chunk)
  let air = @block.AIR_LONG_ID
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      let (wx, _, wz) = chunk.block_rxyz_to_block_xyz(rx, 0, rz)
      let biome = @biome.biome_at(world.noise, wx, wz)
      if biome is @biome.Plains && should_place_oak(world.noise, wx, wz, params) {
        let surface = surface_height(world, wx, wz)
        let base_ry = surface - chunk.y * CHUNK_Y_SIZE
        if rx >= 2 &&
          rx <= CHUNK_X_SIZE - 3 &&
          rz >= 2 &&
          rz <= CHUNK_Z_SIZE - 3 &&
          base_ry >= 0 &&
          base_ry + 1 < CHUNK_Y_SIZE {
          let base = chunk.get_tile(rx, base_ry, rz)
          let above = chunk.get_tile(rx, base_ry + 1, rz)
          if is_grass(base) && above == air {
            let setter = fn(x : Int, y : Int, z : Int, id : UInt) -> Unit {
              region.set_block(x, y, z, id)
            }
            @feature.place_oak_tree_genus(setter, wx, surface + 1, wz)
          }
        }
      }
    }
  }
}
