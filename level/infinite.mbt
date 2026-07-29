///|
/// Infinite bottom layer Y (bedrock).
pub const INFINITE_MIN_Y : Int = WORLD_MIN_Y

///|
const DESERT_LAKE_CELL : Int = 32

///|
const DESERT_LAKE_RADIUS_MIN : Int = 5

///|
const DESERT_LAKE_RADIUS_MAX : Int = 11

///|
const DESERT_LAKE_DEPTH_MIN : Int = 4

///|
const DESERT_LAKE_DEPTH_MAX : Int = 10

///|
const DENSITY_SAMPLE_STEP : Int = 4

///|
priv struct InfiniteColumnSample {
  terrain : TerrainColumn
  dirt_depth : Int
  sand_depth : Int
  top_solid_wy : Int
  inland_min_wy : Int
  densities : Array[Double]
  fluids : Array[TerrainFluid]
}

///|
priv struct InfiniteBlockPalette {
  bedrock : UInt
  stone : UInt
  deepslate : UInt
  grass : UInt
  snow : UInt
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
fn InfiniteBlockPalette::new() -> InfiniteBlockPalette {
  {
    bedrock: @block.lookup_by_name("bedrock").unwrap().id,
    stone: @block.lookup_by_name("stone").unwrap().id,
    deepslate: @block.lookup_by_name("deepslate").unwrap().id,
    grass: @block.lookup_by_name("grass").unwrap().id,
    snow: @block.lookup_by_name("classic.snow").unwrap().id,
    dirt: @block.lookup_by_name("dirt").unwrap().id,
    sand: @block.lookup_by_name("sand").unwrap().id,
    sandstone: @block.lookup_by_name("sandstone").unwrap().id,
    water: @block.lookup_by_name("water").unwrap().id,
    lava: @block.lookup_by_name("lava").unwrap().id,
    coal_ore: @block.lookup_by_name("classic.coal_ore").unwrap().id,
    iron_ore: @block.lookup_by_name("classic.iron_ore").unwrap().id,
    gold_ore: @block.lookup_by_name("classic.gold_ore").unwrap().id,
    redstone_ore: @block.lookup_by_name("classic.redstone_ore").unwrap().id,
    diamond_ore: @block.lookup_by_name("classic.diamond_ore").unwrap().id,
    lapis_ore: @block.lookup_by_name("classic.lapis_ore").unwrap().id,
    emerald_ore: @block.lookup_by_name("classic.emerald_ore").unwrap().id,
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
  let mut lower_y = min_y
  let mut lower_density = density_at_column(world, terrain, lower_y)
  while lower_y < max_y {
    let candidate_y = lower_y + DENSITY_SAMPLE_STEP
    let upper_y = if candidate_y < max_y { candidate_y } else { max_y }
    let upper_density = density_at_column(world, terrain, upper_y)
    let span = (upper_y - lower_y).to_double()
    for wy in lower_y..<upper_y {
      let t = (wy - lower_y).to_double() / span
      densities[wy - min_y] = lower_density +
        (upper_density - lower_density) * t
    }
    lower_y = upper_y
    lower_density = upper_density
  }
  densities[max_y - min_y] = lower_density
  densities
}

///|
fn InfiniteColumnSample::density_at(
  self : InfiniteColumnSample,
  wy : Int,
) -> Double {
  self.densities[wy - INFINITE_MIN_Y]
}

///|
fn InfiniteColumnSample::fluid_at(
  self : InfiniteColumnSample,
  wy : Int,
) -> TerrainFluid {
  self.fluids[wy - INFINITE_MIN_Y]
}

///|
fn noise01(value : Double) -> Double {
  @util.clamp01((value + 1.0) * 0.5)
}

///|
fn lerp_int(min : Int, max : Int, t : Double) -> Int {
  min + ((max - min).to_double() * @util.clamp01(t)).round().to_int()
}

///|
fn clamp_depth(depth : Int) -> Int {
  if depth < 2 {
    2
  } else if depth > 15 {
    15
  } else {
    depth
  }
}

///|
fn is_infinite_bedrock(world : World, wx : Int, wy : Int, wz : Int) -> Bool {
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
fn desert_lake_fill_depth(
  world : World,
  wx : Int,
  wz : Int,
  top_solid_wy : Int,
) -> Int {
  guard top_solid_wy >= SEA_LEVEL - 12 && top_solid_wy <= SEA_LEVEL + 18 else {
    0
  }
  let cell_x = @util.floor_div(wx, DESERT_LAKE_CELL)
  let cell_z = @util.floor_div(wz, DESERT_LAKE_CELL)
  let local_x = wx - cell_x * DESERT_LAKE_CELL
  let local_z = wz - cell_z * DESERT_LAKE_CELL
  let cx = cell_x.to_double()
  let cz = cell_z.to_double()
  let chance = noise01(
    world.noise.gen2d((cx * 47.0 + 3.0) * 0.23, (cz * 37.0 - 5.0) * 0.23),
  )
  guard chance >= 0.58 else { 0 }
  let center_x = lerp_int(
    7,
    DESERT_LAKE_CELL - 7,
    noise01(
      world.noise.gen2d((cx * 31.0 + 9.0) * 0.25, (cz * 29.0 - 4.0) * 0.25),
    ),
  )
  let center_z = lerp_int(
    7,
    DESERT_LAKE_CELL - 7,
    noise01(
      world.noise.gen2d((cx * 11.0 - 7.0) * 0.25, (cz * 41.0 + 2.0) * 0.25),
    ),
  )
  let radius_x = lerp_int(
    DESERT_LAKE_RADIUS_MIN,
    DESERT_LAKE_RADIUS_MAX,
    noise01(
      world.noise.gen2d((cx * 13.0 + 8.0) * 0.21, (cz * 59.0 - 1.0) * 0.21),
    ),
  )
  let radius_z = lerp_int(
    DESERT_LAKE_RADIUS_MIN,
    DESERT_LAKE_RADIUS_MAX,
    noise01(
      world.noise.gen2d((cx * 61.0 - 8.0) * 0.21, (cz * 17.0 + 7.0) * 0.21),
    ),
  )
  let nx = (local_x - center_x).to_double() / radius_x.to_double()
  let nz = (local_z - center_z).to_double() / radius_z.to_double()
  let basin = 1.0 - (nx * nx + nz * nz)
  guard basin > 0.0 else { 0 }
  let base_depth = lerp_int(
    DESERT_LAKE_DEPTH_MIN,
    DESERT_LAKE_DEPTH_MAX,
    noise01(
      world.noise.gen2d((cx * 23.0 + 10.0) * 0.19, (cz * 67.0 - 3.0) * 0.19),
    ),
  )
  clamp_depth(2 + (base_depth.to_double() * basin).round().to_int())
}

///|
/// Prepare all terrain state shared by the vertical chunks at one XZ block
/// coordinate. This is the canonical noise/density cache for column generation.
fn prepare_infinite_column(
  world : World,
  wx : Int,
  wz : Int,
) -> InfiniteColumnSample {
  let terrain = terrain_column(world, wx, wz)
  let densities = sample_column_densities(world, terrain)
  let min_y = world.min_y()
  let max_y = world.max_y()
  let mut top_solid_wy = min_y
  for wy = max_y; wy > min_y; wy = wy - 1 {
    if densities[wy - min_y] > 0.0 {
      top_solid_wy = wy
      break
    }
  }
  let inland_depth = match terrain.surface_biome {
    @biome.DesertLakes => desert_lake_fill_depth(world, wx, wz, top_solid_wy)
    _ => 0
  }
  let inland_min_wy = top_solid_wy - inland_depth + 1
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
    inland_min_wy,
    densities,
    fluids,
  }
}

///|
fn fill_infinite_block(
  world : World,
  chunk : Chunk,
  rx : Int,
  ry : Int,
  rz : Int,
  column : InfiniteColumnSample,
  palette : InfiniteBlockPalette,
) -> Unit {
  let air = @schema.AIR_ID
  let (wx, wy, wz) = chunk.block_rxyz_to_block_xyz(rx, ry, rz)
  if wy < world.min_y() || wy > world.max_y() {
    chunk.update_tile_map(rx, ry, rz, air)
    return
  }
  let biome = column.terrain.surface_biome
  let density = column.density_at(wy)
  let use_inland_water = column.inland_min_wy <= wy && wy <= column.top_solid_wy
  if is_infinite_bedrock(world, wx, wy, wz) {
    chunk.update_tile_map(rx, ry, rz, palette.bedrock)
  } else if use_inland_water {
    chunk.update_tile_map(rx, ry, rz, palette.water)
  } else if density <= 0.0 {
    match column.fluid_at(wy) {
      Air => chunk.update_tile_map(rx, ry, rz, air)
      Water => chunk.update_tile_map(rx, ry, rz, palette.water)
      Lava => chunk.update_tile_map(rx, ry, rz, palette.lava)
    }
  } else if wy == column.top_solid_wy {
    match biome {
      @biome.Ocean
      | @biome.DeepOcean
      | @biome.Desert
      | @biome.DesertLakes
      | @biome.Beach => chunk.update_tile_map(rx, ry, rz, palette.sand)
      @biome.Mountains =>
        if wy >= SEA_LEVEL + 23 {
          chunk.update_tile_map(rx, ry, rz, palette.snow)
        } else {
          chunk.update_tile_map(rx, ry, rz, palette.grass)
        }
      @biome.WindsweptHills =>
        if wy >= SEA_LEVEL + 15 {
          chunk.update_tile_map(rx, ry, rz, palette.snow)
        } else {
          chunk.update_tile_map(rx, ry, rz, palette.grass)
        }
      _ => chunk.update_tile_map(rx, ry, rz, palette.grass)
    }
  } else if (
      biome is @biome.Desert ||
      biome is @biome.DesertLakes ||
      biome is @biome.Beach ||
      biome is @biome.Ocean ||
      biome is @biome.DeepOcean
    ) &&
    wy >= column.top_solid_wy - column.sand_depth {
    chunk.update_tile_map(rx, ry, rz, palette.sand)
  } else if (biome is @biome.Desert || biome is @biome.DesertLakes) &&
    wy >= column.top_solid_wy - column.sand_depth - DESERT_SANDSTONE_DEPTH {
    chunk.update_tile_map(rx, ry, rz, palette.sandstone)
  } else if wy >= column.top_solid_wy - column.dirt_depth {
    chunk.update_tile_map(rx, ry, rz, palette.dirt)
  } else {
    let rock = if wy < 0 { palette.deepslate } else { palette.stone }
    chunk.update_tile_map(
      rx,
      ry,
      rz,
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
      ),
    )
  }
}

///|
fn chunk_has_infinite_surface(
  chunk : Chunk,
  columns : Array[InfiniteColumnSample],
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
  columns : Array[InfiniteColumnSample],
  grass : UInt,
) -> Unit {
  guard chunk_has_infinite_surface(chunk, columns) else {
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
    long_id => long_id == grass,
  )
}

///|
/// Infinite terrain generation (biomes, soil, caves).
fn fill_infinite(world : World, chunk : Chunk) -> Chunk {
  let palette = InfiniteBlockPalette::new()
  let columns : Array[InfiniteColumnSample] = []
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      let (wx, _, wz) = chunk.block_rxyz_to_block_xyz(rx, 0, rz)
      let column = prepare_infinite_column(world, wx, wz)
      columns.push(column)
      for ry in 0..<CHUNK_Y_SIZE {
        fill_infinite_block(world, chunk, rx, ry, rz, column, palette)
      }
    }
  }
  place_biome_trees_in_generated_chunk(world, chunk, columns, palette.grass)
  chunk
}

///|
priv enum InfiniteColumnGenerationStage {
  SampleColumns
  FillColumns
  PlaceTrees
  Complete
}

///|
/// Incremental generation state for one complete Infinite-world chunk column.
/// Completed chunks remain private until every terrain and feature step finishes.
pub struct InfiniteChunkColumnGeneration {
  column_key : String
  advance_impl : (Int) -> Bool
  completed_chunks_impl : () -> Array[Chunk]?
}

///|
priv struct InfiniteChunkColumnGenerationState {
  world : World
  chunk_x : Int
  chunk_z : Int
  chunks : Array[Chunk]
  columns : Array[InfiniteColumnSample]
  palette : InfiniteBlockPalette
  mut stage : InfiniteColumnGenerationStage
  mut next_index : Int
}

///|
pub fn World::begin_infinite_chunk_column_generation(
  world : World,
  chunk_x : Int,
  chunk_z : Int,
) -> InfiniteChunkColumnGeneration {
  let chunks : Array[Chunk] = []
  let chunk_min_y = @util.floor_div(world.min_y(), CHUNK_Y_SIZE)
  let chunk_max_y = @util.floor_div(world.max_y(), CHUNK_Y_SIZE)
  for chunk_y in chunk_min_y..<=chunk_max_y {
    chunks.push(Chunk::new(chunk_x, chunk_y, chunk_z))
  }
  let state = InfiniteChunkColumnGenerationState::{
    world,
    chunk_x,
    chunk_z,
    chunks,
    columns: [],
    palette: InfiniteBlockPalette::new(),
    stage: SampleColumns,
    next_index: 0,
  }
  {
    column_key: chunk_column_key_by_chunk_xz(chunk_x, chunk_z),
    advance_impl: budget => state.advance(budget),
    completed_chunks_impl: () => state.completed_chunks(),
  }
}

///|
pub fn InfiniteChunkColumnGeneration::column_key(
  self : InfiniteChunkColumnGeneration,
) -> String {
  self.column_key
}

///|
fn InfiniteChunkColumnGenerationState::sample_next_column(
  self : InfiniteChunkColumnGenerationState,
) -> Unit {
  let rx = self.next_index / CHUNK_Z_SIZE
  let rz = self.next_index % CHUNK_Z_SIZE
  self.columns.push(
    prepare_infinite_column(
      self.world,
      self.chunk_x * CHUNK_X_SIZE + rx,
      self.chunk_z * CHUNK_Z_SIZE + rz,
    ),
  )
  self.next_index += 1
  if self.next_index == CHUNK_X_SIZE * CHUNK_Z_SIZE {
    self.stage = FillColumns
    self.next_index = 0
  }
}

///|
fn InfiniteChunkColumnGenerationState::fill_next_column(
  self : InfiniteChunkColumnGenerationState,
) -> Unit {
  let rx = self.next_index / CHUNK_Z_SIZE
  let rz = self.next_index % CHUNK_Z_SIZE
  let column = self.columns[self.next_index]
  for chunk in self.chunks {
    for ry in 0..<CHUNK_Y_SIZE {
      fill_infinite_block(self.world, chunk, rx, ry, rz, column, self.palette)
    }
  }
  self.next_index += 1
  if self.next_index == CHUNK_X_SIZE * CHUNK_Z_SIZE {
    self.stage = PlaceTrees
    self.next_index = 0
  }
}

///|
fn InfiniteChunkColumnGenerationState::place_trees(
  self : InfiniteChunkColumnGenerationState,
) -> Unit {
  for chunk in self.chunks {
    place_biome_trees_in_generated_chunk(
      self.world,
      chunk,
      self.columns,
      self.palette.grass,
    )
  }
  self.stage = Complete
}

///|
/// Advance at most `work_budget` bounded XZ or feature work units.
/// Returns true only after the complete vertical column is ready to publish.
fn InfiniteChunkColumnGenerationState::advance(
  self : InfiniteChunkColumnGenerationState,
  work_budget : Int,
) -> Bool {
  guard work_budget > 0 else { return self.stage is Complete }
  for _ in 0..<work_budget {
    match self.stage {
      SampleColumns => self.sample_next_column()
      FillColumns => self.fill_next_column()
      PlaceTrees => self.place_trees()
      Complete => return true
    }
  }
  self.stage is Complete
}

///|
fn InfiniteChunkColumnGenerationState::completed_chunks(
  self : InfiniteChunkColumnGenerationState,
) -> Array[Chunk]? {
  if self.stage is Complete {
    Some(self.chunks)
  } else {
    None
  }
}

///|
pub fn InfiniteChunkColumnGeneration::advance(
  self : InfiniteChunkColumnGeneration,
  work_budget : Int,
) -> Bool {
  (self.advance_impl)(work_budget)
}

///|
pub fn InfiniteChunkColumnGeneration::completed_chunks(
  self : InfiniteChunkColumnGeneration,
) -> Array[Chunk]? {
  (self.completed_chunks_impl)()
}

///|
/// Generate a complete vertical infinite-terrain column. Each XZ sample is
/// prepared once, then consumed by every chunk at that position.
fn generate_infinite_chunk_column(
  world : World,
  chunk_x : Int,
  chunk_z : Int,
) -> Array[Chunk] {
  let generation = world.begin_infinite_chunk_column_generation(
    chunk_x, chunk_z,
  )
  while !generation.advance(64) {

  }
  match generation.completed_chunks() {
    Some(chunks) => chunks
    None => abort("completed infinite column generation has no chunks")
  }
}
