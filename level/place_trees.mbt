///|
pub struct PlacementParams {
  /// Noise frequency controlling density variation scale. 
  /// higher => faster changes over space.
  freq : Double
  /// Density threshold; higher => fewer trees.
  threshold : Double
  /// Minimum spacing between candidate placements (cell size in blocks).
  min_spacing : Int
}

///|
pub const TREE_MIN_SPACE : Int = 4

///|
/// Default oak tree density for plains.
pub let plains_tree_params : PlacementParams = PlacementParams::{
  freq: 0.08,
  threshold: 0.08,
  min_spacing: TREE_MIN_SPACE + 3,
}

///|
pub let forest_tree_params : PlacementParams = PlacementParams::{
  freq: 0.08,
  threshold: -0.08,
  min_spacing: TREE_MIN_SPACE,
}

///|
pub let mountain_tree_params : PlacementParams = PlacementParams::{
  freq: 0.08,
  threshold: 0.14,
  min_spacing: TREE_MIN_SPACE + 2,
}

///|
pub let river_tree_params : PlacementParams = PlacementParams::{
  freq: 0.08,
  threshold: 1.0,
  min_spacing: TREE_MIN_SPACE + 10,
}

///|
pub let frozen_river_tree_params : PlacementParams = PlacementParams::{
  freq: 0.08,
  threshold: 1.0,
  min_spacing: TREE_MIN_SPACE + 10,
}

///|
pub let desert_lakes_tree_params : PlacementParams = PlacementParams::{
  freq: 0.08,
  threshold: 0.3,
  min_spacing: TREE_MIN_SPACE + 5,
}

///|
fn sample_oak_cell_offset(
  cell_x : Int,
  cell_z : Int,
  spacing : Int,
) -> (Int, Int) {
  let ox = @util.Noise::fast(cell_x * 73856093 + cell_z * 19349663 + 9119)
  let oz = @util.Noise::fast(cell_x * 83492791 + cell_z * 297121507 + 2971)
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
  params : PlacementParams,
) -> Bool {
  if params.min_spacing <= 1 {
    noise.gen2d(wx.to_double() * params.freq, wz.to_double() * params.freq) >
    params.threshold
  } else {
    let cell_x = @util.floor_div(wx, params.min_spacing)
    let cell_z = @util.floor_div(wz, params.min_spacing)
    let (ox, oz) = sample_oak_cell_offset(cell_x, cell_z, params.min_spacing)
    let target_x = cell_x * params.min_spacing + ox
    let target_z = cell_z * params.min_spacing + oz
    if wx != target_x || wz != target_z {
      false
    } else {
      let density = noise.gen2d(
        target_x.to_double() * params.freq,
        target_z.to_double() * params.freq,
      )
      let cell_jitter = @util.Noise::fast(
          cell_x * 961748927 + cell_z * 982451653 + 719,
        ) *
        0.22
      density + cell_jitter > params.threshold
    }
  }
}

///|
fn tree_profile_for_biome(
  noise : @util.PerlinNoise,
  wx : Int,
  wz : Int,
  biome : @biome.Biome,
  oak_log : @block.Block,
  birch_log : @block.Block,
  spruce_log : @block.Block,
  acacia_log : @block.Block,
  jungle_log : @block.Block,
) -> (PlacementParams, @block.Block)? {
  let mix = noise.gen2d(wx.to_double() * 0.013, wz.to_double() * 0.013)
  match biome {
    @biome.Plains =>
      if mix > 0.58 {
        Some((plains_tree_params, birch_log))
      } else if mix < -0.62 {
        Some((plains_tree_params, acacia_log))
      } else {
        Some((plains_tree_params, oak_log))
      }
    @biome.Forest =>
      if mix > 0.45 {
        Some((forest_tree_params, spruce_log))
      } else if mix > 0.1 {
        Some((forest_tree_params, birch_log))
      } else if mix < -0.5 {
        Some((forest_tree_params, jungle_log))
      } else {
        Some((forest_tree_params, oak_log))
      }
    @biome.Mountains => Some((mountain_tree_params, spruce_log))
    @biome.WindsweptHills => Some((mountain_tree_params, spruce_log))
    @biome.River =>
      if mix > 0.4 {
        Some((river_tree_params, jungle_log))
      } else {
        Some((river_tree_params, oak_log))
      }
    @biome.FrozenRiver => Some((frozen_river_tree_params, spruce_log))
    @biome.DesertLakes => Some((desert_lakes_tree_params, acacia_log))
    @biome.Desert => Some((desert_lakes_tree_params, acacia_log))
    _ => None
  }
}

///|
fn can_place_tree_on_biome_surface(
  biome : @biome.Biome,
  base : UInt,
  grass : UInt,
  dirt : UInt,
  sand : UInt,
  snow : UInt,
) -> Bool {
  match biome {
    @biome.Desert => base == sand
    @biome.DesertLakes => base == sand
    @biome.Beach => false
    @biome.Ocean => false
    @biome.DeepOcean => false
    @biome.Mountains => base == grass || base == snow || base == dirt
    @biome.WindsweptHills => base == grass || base == snow || base == dirt
    _ => base == grass || base == dirt
  }
}

///|
fn find_tree_base_ry(chunk : Chunk, rx : Int, rz : Int, air : UInt) -> Int? {
  for ry = CHUNK_Y_SIZE - 2; ry >= 0; {
    let base = chunk.get_tile(rx, ry, rz)
    let above = chunk.get_tile(rx, ry + 1, rz)
    if base != air && above == air {
      return Some(ry)
    }
    continue ry - 1
  } nobreak {
    None
  }
}

///|
pub fn place_oak_trees_in_chunk(
  world : World,
  chunk : Chunk,
  params? : PlacementParams = plains_tree_params,
  is_grass? : (UInt) -> Bool = long_id => {
    long_id == @block.lookup_by_name("grass").unwrap().id
  },
) -> Unit {
  apply_pending_to_chunk(chunk)
  let region = ChunkRegion::new(chunk)
  let air = @block.AIR_LONG_ID
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      let (wx, _, wz) = chunk.block_rxyz_to_block_xyz(rx, 0, rz)
      let column = terrain_column(world, wx, wz)
      let biome = column.surface_biome
      if biome is @biome.Plains && should_place_oak(world.noise, wx, wz, params) {
        if rx >= 2 &&
          rx <= CHUNK_X_SIZE - 3 &&
          rz >= 2 &&
          rz <= CHUNK_Z_SIZE - 3 {
          match find_tree_base_ry(chunk, rx, rz, air) {
            None => ()
            Some(base_ry) => {
              let base = chunk.get_tile(rx, base_ry, rz)
              if is_grass(base) {
                let (_, surface, _) = chunk.block_rxyz_to_block_xyz(
                  rx, base_ry, rz,
                )
                let setter = fn(x : Int, y : Int, z : Int, id : UInt) -> Unit {
                  region.set_block(x, y, z, id)
                }
                @feature.place_oak_tree_genus(setter, wx, surface, wz)
              }
            }
          }
        }
      }
    }
  }
}

///|
/// Biome-aware tree placement for Infinite world.
/// Uses oak tree feature geometry with species-specific log/leaves fillers.
pub fn place_biome_trees_in_chunk(
  world : World,
  chunk : Chunk,
  is_grass? : (UInt) -> Bool = long_id => {
    long_id == @block.lookup_by_name("grass").unwrap().id
  },
) -> Unit {
  apply_pending_to_chunk(chunk)
  let region = ChunkRegion::new(chunk)
  let air = @block.AIR_LONG_ID
  let grass_id = @block.lookup_by_name("grass").unwrap().id
  let dirt_id = @block.lookup_by_name("dirt").unwrap().id
  let sand_id = @block.lookup_by_name("sand").unwrap().id
  let snow_id = @block.lookup_by_name("classic.snow").unwrap().id
  let oak_log = @block.lookup_by_name("classic.oak_log").unwrap()
  let birch_log = @block.lookup_by_name("classic.birch_log").unwrap()
  let spruce_log = @block.lookup_by_name("classic.spruce_log").unwrap()
  let acacia_log = @block.lookup_by_name("classic.acacia_log").unwrap()
  let jungle_log = @block.lookup_by_name("classic.jungle_log").unwrap()
  let leaves_id = @block.lookup_by_name("oak_leaves").unwrap().id
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      let (wx, _, wz) = chunk.block_rxyz_to_block_xyz(rx, 0, rz)
      let column = terrain_column(world, wx, wz)
      let biome = column.surface_biome
      match
        tree_profile_for_biome(
          world.noise,
          wx,
          wz,
          biome,
          oak_log,
          birch_log,
          spruce_log,
          acacia_log,
          jungle_log,
        ) {
        None => ()
        Some((params, log_block)) =>
          if should_place_oak(world.noise, wx, wz, params) {
            if rx >= 2 &&
              rx <= CHUNK_X_SIZE - 3 &&
              rz >= 2 &&
              rz <= CHUNK_Z_SIZE - 3 {
              match find_tree_base_ry(chunk, rx, rz, air) {
                None => ()
                Some(base_ry) => {
                  let base = chunk.get_tile(rx, base_ry, rz)
                  if can_place_tree_on_biome_surface(
                      biome, base, grass_id, dirt_id, sand_id, snow_id,
                    ) &&
                    (
                      is_grass(base) ||
                      base == dirt_id ||
                      base == sand_id ||
                      base == snow_id
                    ) {
                    let (_, surface, _) = chunk.block_rxyz_to_block_xyz(
                      rx, base_ry, rz,
                    )
                    let setter = fn(
                      x : Int,
                      y : Int,
                      z : Int,
                      id : UInt,
                    ) -> Unit {
                      region.set_block(x, y, z, id)
                    }
                    @feature.place_oak_tree_genus(
                      setter,
                      wx,
                      surface,
                      wz,
                      filler_log=log_block,
                      filler_leaves=leaves_id,
                    )
                  }
                }
              }
            }
          }
      }
    }
  }
}
