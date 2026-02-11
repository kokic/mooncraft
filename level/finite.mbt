///|
/// Finite world size (blocks).
pub const FINITE_WORLD_X_SIZE : Int = 256

///|
/// Finite world size (blocks).
pub const FINITE_WORLD_Y_SIZE : Int = 128

///|
/// Finite world size (blocks).
pub const FINITE_WORLD_Z_SIZE : Int = 256

///|
pub const FINITE_MIN_Y : Int = -FINITE_WORLD_Y_SIZE / 2

///|
pub const FINITE_MAX_Y : Int = -FINITE_MIN_Y - 1

///|
pub const FINITE_CHUNK_X_HALF : Int = FINITE_WORLD_X_SIZE / (2 * CHUNK_X_SIZE)

///|
pub const FINITE_CHUNK_Y_HALF : Int = FINITE_WORLD_Y_SIZE / (2 * CHUNK_Y_SIZE)

///|
pub const FINITE_CHUNK_Z_HALF : Int = FINITE_WORLD_Z_SIZE / (2 * CHUNK_Z_SIZE)

///|
fn is_chunk_in_finite_world(
  chunk_x : Int,
  chunk_y : Int,
  chunk_z : Int,
) -> Bool {
  chunk_x >= -FINITE_CHUNK_X_HALF &&
  chunk_x < FINITE_CHUNK_X_HALF &&
  chunk_y >= -FINITE_CHUNK_Y_HALF &&
  chunk_y < FINITE_CHUNK_Y_HALF &&
  chunk_z >= -FINITE_CHUNK_X_HALF &&
  chunk_z < FINITE_CHUNK_X_HALF
}

///|
const FINITE_BIOME_COORD_SCALE : Double = 1.95

///|
const FINITE_BASE_HEIGHT : Double = 8.0

///|
const FINITE_ROLLING_FREQ : Double = 0.0065

///|
const FINITE_ROLLING_AMP : Double = 9.0

///|
const FINITE_DETAIL_FREQ : Double = 0.020

///|
const FINITE_DETAIL_AMP : Double = 2.6

///|
const FINITE_MOUNTAIN_BONUS : Double = 7.0

///|
const FINITE_WINDSWEPT_BONUS : Double = 4.8

///|
const FINITE_MOUNTAIN_RIDGE_BONUS : Double = 5.4

///|
const FINITE_MOUNTAIN_EROSION_PENALTY : Double = 4.8

///|
const FINITE_SURFACE_SOLID_BIAS : Double = 0.85

///|
const FINITE_DIRT_SCALE : Double = 19.0

///|
const FINITE_SAND_SCALE : Double = 17.0

///|
const FINITE_SAND_DEPTH_MIN : Int = 3

///|
const FINITE_SAND_DEPTH_MAX : Int = 5

///|
const FINITE_CAVE_FREQ_A : Double = 0.041

///|
const FINITE_CAVE_FREQ_B : Double = 0.068

///|
const FINITE_CAVE_THRESHOLD : Double = 0.12

///|
const FINITE_CAVE_REGION_FREQ : Double = 0.018

///|
const FINITE_CAVE_REGION_THRESHOLD : Double = 0.45

///|
fn finite_clamp01(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
fn finite_scaled_coord(coord : Int) -> Int {
  (coord.to_double() * FINITE_BIOME_COORD_SCALE).round().to_int()
}

///|
fn finite_surface_biome(
  sample : @biome.BiomeSample,
  biome : @biome.Biome,
) -> @biome.Biome {
  match biome {
    @biome.Ocean | @biome.DeepOcean | @biome.River | @biome.FrozenRiver =>
      fallback_dry_land_biome(sample)
    _ => biome
  }
}

///|
fn finite_terrain_column(world : World, wx : Int, wz : Int) -> TerrainColumn {
  let sx = finite_scaled_coord(wx)
  let sz = finite_scaled_coord(wz)
  let sample = @biome.sample(world.noise, sx, sz)
  let biome = @biome.biome_from_sample(sample)
  let surface_biome = finite_surface_biome(sample, biome)
  let x = wx.to_double()
  let z = wz.to_double()
  let erosion_t = finite_clamp01((sample.erosion + 1.0) * 0.5)
  let rolling = @biome.fbm2d(
      world.noise,
      x * FINITE_ROLLING_FREQ,
      z * FINITE_ROLLING_FREQ,
      4,
      2.0,
      0.5,
    ) *
    FINITE_ROLLING_AMP
  let detail = world.noise.gen2d(x * FINITE_DETAIL_FREQ, z * FINITE_DETAIL_FREQ) *
    FINITE_DETAIL_AMP
  let climate = sample.humidity * 1.15 - sample.temperature.abs() * 0.50
  let mut surface = FINITE_BASE_HEIGHT +
    rolling +
    detail +
    climate +
    max0(sample.continental) * 4.2
  match surface_biome {
    @biome.Mountains =>
      surface = surface +
        FINITE_MOUNTAIN_BONUS +
        sample.ridge * FINITE_MOUNTAIN_RIDGE_BONUS -
        erosion_t * FINITE_MOUNTAIN_EROSION_PENALTY
    @biome.WindsweptHills =>
      surface = surface +
        FINITE_WINDSWEPT_BONUS +
        sample.ridge * 3.2 -
        erosion_t * 2.0
    @biome.Forest => surface = surface + 0.8
    @biome.Desert => surface = surface - 0.8
    @biome.DesertLakes => surface = surface - 1.4
    @biome.Beach => surface = surface - 2.2
    _ => ()
  }
  let min_h = FINITE_MIN_Y + 4
  let max_h = FINITE_MAX_Y - 2
  let mut surface_i = surface.round().to_int()
  if surface_i < min_h {
    surface_i = min_h
  } else if surface_i > max_h {
    surface_i = max_h
  }
  let plain_drop = if surface_biome is @biome.Mountains {
    5
  } else if surface_biome is @biome.WindsweptHills {
    4
  } else {
    3
  }
  let mut plain = surface_i - plain_drop
  if plain < min_h - 2 {
    plain = min_h - 2
  }
  TerrainColumn::{
    wx,
    wz,
    sample,
    biome,
    surface_biome,
    plain,
    surface: surface_i,
  }
}

///|
fn finite_dirt_depth(world : World, wx : Int, wz : Int) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let detail = world.noise
    .gen2d(x / FINITE_DIRT_SCALE, z / FINITE_DIRT_SCALE)
    .abs()
  2 + (detail * 2.0).floor().to_int()
}

///|
fn finite_sand_depth(world : World, wx : Int, wz : Int) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let t = world.noise.gen2d(x / FINITE_SAND_SCALE, z / FINITE_SAND_SCALE).abs()
  FINITE_SAND_DEPTH_MIN +
  (t * (FINITE_SAND_DEPTH_MAX - FINITE_SAND_DEPTH_MIN).to_double())
  .floor()
  .to_int()
}

///|
fn finite_density_at_column(
  world : World,
  column : TerrainColumn,
  wy : Int,
) -> Double {
  let y = wy.to_double()
  let surface = column.surface.to_double()
  if y > surface {
    -1.0
  } else if wy <= FINITE_MIN_Y + 1 {
    1.0
  } else {
    let x = column.wx.to_double()
    let z = column.wz.to_double()
    let vertical = surface - y
    let cave_main = world.noise
      .gen3d(
        x * FINITE_CAVE_FREQ_A,
        y * FINITE_CAVE_FREQ_A,
        z * FINITE_CAVE_FREQ_A,
      )
      .abs()
    let cave_aux = world.noise
      .gen3d(
        (x + 271.0) * FINITE_CAVE_FREQ_B,
        y * FINITE_CAVE_FREQ_B,
        (z - 433.0) * FINITE_CAVE_FREQ_B,
      )
      .abs()
    let cave_mix = cave_main * 0.72 + cave_aux * 0.28
    let cave_threshold = FINITE_CAVE_THRESHOLD + column.sample.erosion * 0.015
    let cave_region = world.noise.gen3d(
      (x - 311.0) * FINITE_CAVE_REGION_FREQ,
      y * FINITE_CAVE_REGION_FREQ,
      (z + 619.0) * FINITE_CAVE_REGION_FREQ,
    )
    if wy < column.surface - 7 &&
      cave_mix < cave_threshold &&
      cave_region > FINITE_CAVE_REGION_THRESHOLD {
      -1.0
    } else {
      let mut density = vertical + FINITE_SURFACE_SOLID_BIAS
      if column.surface_biome is @biome.Mountains ||
        column.surface_biome is @biome.WindsweptHills {
        density = density + 0.6
      }
      if density <= 0.0 {
        -1.0
      } else {
        density
      }
    }
  }
}

///|
fn ranges_overlap(min_a : Int, max_a : Int, min_b : Int, max_b : Int) -> Bool {
  !(max_a < min_b || max_b < min_a)
}

///|
fn chunk_intersects_nether_spire(world : World, chunk : Chunk) -> Bool {
  let base_y = finite_terrain_column(world, 0, 0).surface
  let half = @structure.NETHER_SPIRE_SIZE / 2
  let min_x = -half
  let max_x = min_x + @structure.NETHER_SPIRE_SIZE - 1
  let min_z = -half
  let max_z = min_z + @structure.NETHER_SPIRE_SIZE - 1
  let min_y = base_y + @structure.NETHER_SPIRE_LAYER_Y_MIN
  let max_y = min_y + @structure.NETHER_SPIRE_HEIGHT - 1
  let chunk_min_x = chunk.x * CHUNK_X_SIZE
  let chunk_max_x = chunk_min_x + CHUNK_X_SIZE - 1
  let chunk_min_y = chunk.y * CHUNK_Y_SIZE
  let chunk_max_y = chunk_min_y + CHUNK_Y_SIZE - 1
  let chunk_min_z = chunk.z * CHUNK_Z_SIZE
  let chunk_max_z = chunk_min_z + CHUNK_Z_SIZE - 1
  ranges_overlap(min_x, max_x, chunk_min_x, chunk_max_x) &&
  ranges_overlap(min_y, max_y, chunk_min_y, chunk_max_y) &&
  ranges_overlap(min_z, max_z, chunk_min_z, chunk_max_z)
}

///|
fn place_nether_spire_in_chunk(world : World, chunk : Chunk) -> Unit {
  let base_y = finite_terrain_column(world, 0, 0).surface
  let setter = fn(wx : Int, wy : Int, wz : Int, long_id : UInt) -> Unit {
    Chunk::set_block(chunk, wx, wy, wz, long_id)
  }
  @structure.place_nether_spire(setter, 0, base_y, 0)
}

///|
/// Finite world terrain generation (256 x 128 x 256).
fn fill_finite(world : World, chunk : Chunk) -> Chunk {
  let air = @block.AIR_LONG_ID
  let bedrock = @block.lookup_by_name("bedrock").unwrap().id
  let stone = @block.lookup_by_name("stone").unwrap().id
  let grass = @block.lookup_by_name("grass").unwrap().id
  let dirt = @block.lookup_by_name("dirt").unwrap().id
  let sand = @block.lookup_by_name("sand").unwrap().id
  let sandstone = @block.lookup_by_name("sandstone").unwrap().id
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      let (wx, _, wz) = chunk.block_rxyz_to_block_xyz(rx, 0, rz)
      let column = finite_terrain_column(world, wx, wz)
      let biome = column.surface_biome
      let dirt_depth = finite_dirt_depth(world, wx, wz)
      let sand_depth = finite_sand_depth(world, wx, wz)
      let surface = column.surface
      for ry in 0..<CHUNK_Y_SIZE {
        let (_, wy, _) = chunk.block_rxyz_to_block_xyz(rx, ry, rz)
        let density = finite_density_at_column(world, column, wy)
        if wy < FINITE_MIN_Y {
          chunk.update_tile_map(rx, ry, rz, air)
        } else if wy == FINITE_MIN_Y {
          chunk.update_tile_map(rx, ry, rz, bedrock)
        } else if density <= 0.0 {
          chunk.update_tile_map(rx, ry, rz, air)
        } else if wy == surface {
          match biome {
            @biome.Desert => chunk.update_tile_map(rx, ry, rz, sand)
            _ => chunk.update_tile_map(rx, ry, rz, grass)
          }
        } else if biome is @biome.Desert && wy >= surface - sand_depth {
          chunk.update_tile_map(rx, ry, rz, sand)
        } else if biome is @biome.Desert &&
          wy >= surface - sand_depth - DESERT_SANDSTONE_DEPTH {
          chunk.update_tile_map(rx, ry, rz, sandstone)
        } else if wy >= surface - dirt_depth {
          chunk.update_tile_map(rx, ry, rz, dirt)
        } else {
          chunk.update_tile_map(rx, ry, rz, stone)
        }
      }
    }
  }
  place_biome_trees_in_chunk(world, chunk)
  if chunk_intersects_nether_spire(world, chunk) {
    place_nether_spire_in_chunk(world, chunk)
  }
  chunk
}
