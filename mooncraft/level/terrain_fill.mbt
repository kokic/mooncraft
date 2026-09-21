///|
/// Bottom layer Y (bedrock) for Infinite and Finite worlds.
pub const TERRAIN_MIN_Y : Int = WORLD_MIN_Y

///|
const DENSITY_SAMPLE_STEP : Int = 4

///|
/// Tree anchors stop below high mountain peaks; canopies may extend above it.
const TREE_LINE : Int = 144

///|
priv struct TerrainColumnSample {
  terrain : TerrainColumn
  dirt_depth : Int
  sand_depth : Int
  top_solid_wy : Int
  densities : Array[Double]
  fluids : Array[TerrainFluid]
}

///|
priv struct TerrainBlockPalette {
  bedrock : UInt
  stone : UInt
  deepslate : UInt
  grass : UInt
  snow : UInt
  gravel : UInt
  ice : UInt
  dirt : UInt
  sand : UInt
  sandstone : UInt
  water : UInt
  lava : UInt
  coal_ore : UInt
  iron_ore : UInt
  gold_ore : UInt
  redstone_ore : UInt
  diamond_ore : UInt
  lapis_ore : UInt
  emerald_ore : UInt
}

///|
fn TerrainBlockPalette::new() -> TerrainBlockPalette {
  {
    bedrock: @block.lookup_by_name("bedrock").unwrap().internal_id(),
    stone: @block.lookup_by_name("stone").unwrap().internal_id(),
    deepslate: @block.lookup_by_name("deepslate").unwrap().internal_id(),
    grass: @block.lookup_by_name("grass").unwrap().internal_id(),
    snow: @block.lookup_by_name("classic.snow").unwrap().internal_id(),
    gravel: @block.lookup_by_name("classic.gravel").unwrap().internal_id(),
    ice: @block.lookup_by_name("classic.ice").unwrap().internal_id(),
    dirt: @block.lookup_by_name("dirt").unwrap().internal_id(),
    sand: @block.lookup_by_name("sand").unwrap().internal_id(),
    sandstone: @block.lookup_by_name("sandstone").unwrap().internal_id(),
    water: @block.lookup_by_name("water").unwrap().internal_id(),
    lava: @block.lookup_by_name("lava").unwrap().internal_id(),
    coal_ore: @block.lookup_by_name("classic.coal_ore").unwrap().internal_id(),
    iron_ore: @block.lookup_by_name("classic.iron_ore").unwrap().internal_id(),
    gold_ore: @block.lookup_by_name("classic.gold_ore").unwrap().internal_id(),
    redstone_ore: @block.lookup_by_name("classic.redstone_ore")
    .unwrap()
    .internal_id(),
    diamond_ore: @block.lookup_by_name("classic.diamond_ore")
    .unwrap()
    .internal_id(),
    lapis_ore: @block.lookup_by_name("classic.lapis_ore").unwrap().internal_id(),
    emerald_ore: @block.lookup_by_name("classic.emerald_ore")
    .unwrap()
    .internal_id(),
  }
}

///|
fn sample_column_densities(
  world : World,
  terrain : TerrainColumn,
) -> Array[Double] {
  let min_y = world.min_y()
  let max_y = world.max_y()
  let height = max_y - min_y + 1
  let densities = Array::make(height, -1.0)
  let shape = TerrainShape::at_column(world, terrain)
  let mut lower_y = min_y
  let mut lower_density = terrain_shape_density(world, terrain, lower_y, shape)
  while lower_y < max_y {
    let candidate_y = lower_y + DENSITY_SAMPLE_STEP
    let upper_y = if candidate_y < max_y { candidate_y } else { max_y }
    let upper_density = terrain_shape_density(world, terrain, upper_y, shape)
    let span = (upper_y - lower_y).to_double()
    for wy in lower_y..<upper_y {
      let t = (wy - lower_y).to_double() / span
      let base_density = lower_density + (upper_density - lower_density) * t
      // Interpolate the continuous base field, then carve at block resolution.
      // Interpolating a -1 cave marker against deep positive rock closes tunnels.
      densities[wy - min_y] = carve_terrain_density(
        world, terrain, wy, base_density,
      )
    }
    lower_y = upper_y
    lower_density = upper_density
  }
  densities[max_y - min_y] = carve_terrain_density(
    world, terrain, max_y, lower_density,
  )
  densities
}

///|
fn highest_solid_y(world : World, densities : Array[Double]) -> Int {
  for wy = world.max_y(); wy > world.min_y(); wy = wy - 1 {
    guard densities[wy - world.min_y()] > 0.0 else { continue }
    return wy
  }
  world.min_y()
}

///|
fn TerrainColumnSample::density_at(
  self : TerrainColumnSample,
  wy : Int,
) -> Double {
  self.densities[wy - TERRAIN_MIN_Y]
}

///|
fn TerrainColumnSample::fluid_at(
  self : TerrainColumnSample,
  wy : Int,
) -> TerrainFluid {
  self.fluids[wy - TERRAIN_MIN_Y]
}

///|
fn noise01(value : Double) -> Double {
  @util.clamp01((value + 1.0) * 0.5)
}

///|
fn is_terrain_bedrock(world : World, wx : Int, wy : Int, wz : Int) -> Bool {
  let layer = wy - world.min_y()
  guard layer >= 0 && layer < 5 else { false }
  guard layer > 0 else { true }
  let coordinate_seed = wx * 73428767 +
    wy * 42317861 +
    wz * 912931 +
    world.seed.reinterpret_as_int()
  noise01(@util.Noise::fast(coordinate_seed)) < (5 - layer).to_double() / 5.0
}

///|
/// Prepare all terrain state shared by the vertical chunks at one XZ block
/// coordinate. This is the canonical noise/density cache for column generation.
fn prepare_terrain_column(
  world : World,
  wx : Int,
  wz : Int,
) -> TerrainColumnSample {
  let terrain = terrain_column(world, wx, wz)
  let densities = sample_column_densities(world, terrain)
  let min_y = world.min_y()
  let max_y = world.max_y()
  let top_solid_wy = highest_solid_y(world, densities)
  let fluids : Array[TerrainFluid] = []
  for wy in min_y..<=max_y {
    let density = densities[wy - min_y]
    fluids.push(
      if density <= 0.0 {
        aquifer_fluid_at(world, terrain, wy, top_solid_wy)
      } else {
        Air
      },
    )
  }
  {
    terrain,
    dirt_depth: surface_dirt_depth(world, wx, wz),
    sand_depth: desert_sand_depth(world, wx, wz),
    top_solid_wy,
    densities,
    fluids,
  }
}

///|
/// The block at the top of a solid column: sand for arid and ocean biomes,
/// snow at mountain elevations, gravel in rivers, stone on peaks, grass otherwise.
fn top_surface_block(
  world : World,
  column : TerrainColumn,
  wy : Int,
  palette : TerrainBlockPalette,
) -> UInt {
  let biome = column.surface_biome
  let snow_line = world.terrain_wy_at_field_y(
    140.0 + column.sample.temperature * 40.0,
  )
  guard wy.to_double() < snow_line else { palette.snow }
  match biome {
    @biome.Ocean
    | @biome.DeepOcean
    | @biome.Desert
    | @biome.DesertLakes
    | @biome.Beach => palette.sand
    @biome.River | @biome.FrozenRiver => palette.gravel
    @biome.Mountains => palette.stone
    _ => palette.grass
  }
}

///|
/// The block for a fluid cell: air above the aquifer, water or lava below.
fn fluid_block(fluid : TerrainFluid, palette : TerrainBlockPalette) -> UInt {
  match fluid {
    Air => @schema.AIR_ID
    Water => palette.water
    Lava => palette.lava
  }
}

///|
/// Rock block for a solid below-surface cell: deepslate below the world's
/// deepslate level, ore by layered noise bands above.
fn underground_rock(
  world : World,
  wx : Int,
  wy : Int,
  wz : Int,
  biome : @biome.Biome,
  palette : TerrainBlockPalette,
) -> UInt {
  let rock = if wy < world.deepslate_level() {
    palette.deepslate
  } else {
    palette.stone
  }
  @feature.pick_stone_ore(
    world.noise,
    wx,
    wy,
    wz,
    biome is @biome.Mountains || biome is @biome.WindsweptHills,
    rock,
    palette.coal_ore,
    palette.iron_ore,
    palette.gold_ore,
    palette.redstone_ore,
    palette.diamond_ore,
    palette.lapis_ore,
    palette.emerald_ore,
  )
}

///|
fn fill_terrain_block(
  world : World,
  chunk : Chunk,
  rx : Int,
  ry : Int,
  rz : Int,
  column : TerrainColumnSample,
  palette : TerrainBlockPalette,
) -> Unit {
  let (wx, wy, wz) = chunk.block_rxyz_to_block_xyz(rx, ry, rz)
  if wy < world.min_y() || wy > world.max_y() {
    chunk.update_tile_map(rx, ry, rz, @schema.AIR_ID)
    return
  }
  let biome = column.terrain.surface_biome
  let density = column.density_at(wy)
  let block = if is_terrain_bedrock(world, wx, wy, wz) {
    palette.bedrock
  } else if density <= 0.0 {
    if biome is @biome.FrozenRiver &&
      wy == world.sea_level() &&
      column.fluid_at(wy) is Water {
      palette.ice
    } else {
      fluid_block(column.fluid_at(wy), palette)
    }
  } else if wy == column.top_solid_wy {
    top_surface_block(world, column.terrain, wy, palette)
  } else if (
      biome is @biome.Desert ||
      biome is @biome.DesertLakes ||
      biome is @biome.Beach ||
      biome is @biome.Ocean ||
      biome is @biome.DeepOcean
    ) &&
    wy >= column.top_solid_wy - column.sand_depth {
    palette.sand
  } else if (biome is @biome.Desert || biome is @biome.DesertLakes) &&
    wy >= column.top_solid_wy - column.sand_depth - DESERT_SANDSTONE_DEPTH {
    palette.sandstone
  } else if wy >= column.top_solid_wy - column.dirt_depth &&
    !(biome is @biome.Mountains) {
    palette.dirt
  } else {
    underground_rock(world, wx, wy, wz, biome, palette)
  }
  chunk.update_tile_map(rx, ry, rz, block)
}

///|
fn chunk_has_terrain_surface(
  chunk : Chunk,
  columns : Array[TerrainColumnSample],
) -> Bool {
  let min_y = chunk.y * CHUNK_Y_SIZE
  let max_y = min_y + CHUNK_Y_SIZE
  columns.any(column => {
    column.top_solid_wy >= min_y && column.top_solid_wy < max_y
  })
}

///|
fn place_biome_trees_in_generated_chunk(
  world : World,
  chunk : Chunk,
  columns : Array[TerrainColumnSample],
  grass : UInt,
) -> Unit {
  guard chunk.y * CHUNK_Y_SIZE < TREE_LINE &&
    chunk_has_terrain_surface(chunk, columns) else {
    apply_pending_to_chunk(chunk)
    return
  }
  let base_x = chunk.x * CHUNK_X_SIZE
  let base_z = chunk.z * CHUNK_Z_SIZE
  place_biome_trees_in_chunk_with_biome(
    world,
    chunk,
    (wx, wz) => {
      let rx = wx - base_x
      let rz = wz - base_z
      columns[rx * CHUNK_Z_SIZE + rz].terrain.surface_biome
    },
    internal_id => internal_id == grass,
  )
}

///|
/// Shared terrain generation (biomes, soil, caves, aquifers) for Infinite and
/// Finite worlds. Finite only differs by its field compression and chunk bounds.
fn fill_terrain(world : World, chunk : Chunk) -> Chunk {
  let palette = TerrainBlockPalette::new()
  let columns : Array[TerrainColumnSample] = []
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      let (wx, _, wz) = chunk.block_rxyz_to_block_xyz(rx, 0, rz)
      let column = prepare_terrain_column(world, wx, wz)
      columns.push(column)
      for ry in 0..<CHUNK_Y_SIZE {
        fill_terrain_block(world, chunk, rx, ry, rz, column, palette)
      }
    }
  }
  place_biome_trees_in_generated_chunk(world, chunk, columns, palette.grass)
  chunk
}
