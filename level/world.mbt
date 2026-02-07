///|
pub struct World {
  seed : UInt64
  kind : WorldType
  noise : @util.PerlinNoise
}

///|
pub(all) struct TerrainColumn {
  wx : Int
  wz : Int
  sample : @biome.BiomeSample
  biome : @biome.Biome
  surface_biome : @biome.Biome
  plain : Int
  surface : Int
}

///|
/// Highest world Y for Infinite/Flat worlds.
pub const WORLD_MAX_Y : Int = 127

///|
/// Lowest world Y for Infinite/Flat worlds.
pub const WORLD_MIN_Y : Int = -64

///|
const MIN_TERRAIN_HEIGHT : Int = WORLD_MIN_Y + 1

///|
const MAX_TERRAIN_HEIGHT : Int = WORLD_MAX_Y - 1

///|
/// Minecraft-like sea level baseline.
pub const SEA_LEVEL : Int = 63

///|
const DETAIL_SCALE : Double = 26.0

///|
const PV_FREQ : Double = 0.0105

///|
const RIVER_CARVE_WIDTH : Double = 0.038

///|
const PLAINS_WAVE_FREQ : Double = 0.0075

///|
const PLAINS_WAVE_AMP : Double = 3.2

///|
const HILL_FREQ : Double = 0.0038

///|
const HILL_AMP : Double = 8.0

///|
const PLAINS_WARP_FREQ : Double = 0.0028

///|
const PLAINS_WARP_AMP : Double = 28.0

///|
const MOUNTAIN_WARP_FREQ : Double = 0.0024

///|
const MOUNTAIN_WARP_AMP : Double = 42.0

///|
const MOUNTAIN_RIDGE_FREQ_A : Double = 0.0078

///|
const MOUNTAIN_RIDGE_FREQ_B : Double = 0.016

///|
const TERRAIN_3D_FREQ : Double = 0.018

///|
const TERRAIN_3D_AMP : Double = 2.2

///|
const CAVE_FREQ : Double = 0.030

///|
const CAVE_THRESHOLD : Double = 0.09

///|
const CAVE_REGION_FREQ : Double = 0.010

///|
const CAVE_REGION_THRESHOLD : Double = 0.62

///|
const DESERT_SAND_DEPTH_MIN : Int = 4

///|
const DESERT_SAND_DEPTH_MAX : Int = 7

///|
const DESERT_SAND_SCALE : Double = 24.0

///|
pub const DESERT_SANDSTONE_DEPTH : Int = 4

///|
const WATER_CONTEXT_MAX_HINT : Double = 75.0

///|
const WATER_CONTEXT_FADE : Double = 22.0

///|
const WATER_CONTEXT_ENABLE_THRESHOLD : Double = 0.28

///|
const FALLBACK_DESERT_TEMP_THRESHOLD : Double = 0.34

///|
const FALLBACK_DESERT_HUMID_MAX : Double = -0.03

///|
const FALLBACK_DESERT_LAKES_EROSION_MIN : Double = 0.08

///|
const FALLBACK_DESERT_LAKES_CONTINENTAL_MAX : Double = 0.26

///|
const FALLBACK_FOREST_HUMID_MIN : Double = 0.12

///|
fn clamp01(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
fn max0(value : Double) -> Double {
  if value > 0.0 {
    value
  } else {
    0.0
  }
}

///|
fn smoothstep(edge0 : Double, edge1 : Double, value : Double) -> Double {
  if edge0 >= edge1 {
    if value < edge0 {
      0.0
    } else {
      1.0
    }
  } else {
    let t = clamp01((value - edge0) / (edge1 - edge0))
    t * t * (3.0 - 2.0 * t)
  }
}

fn fallback_land_biome(sample : @biome.BiomeSample) -> @biome.Biome {
  if sample.temperature > FALLBACK_DESERT_TEMP_THRESHOLD &&
    sample.humidity < FALLBACK_DESERT_HUMID_MAX {
    if sample.erosion > FALLBACK_DESERT_LAKES_EROSION_MIN &&
      sample.continental < FALLBACK_DESERT_LAKES_CONTINENTAL_MAX {
      @biome.DesertLakes
    } else {
      @biome.Desert
    }
  } else if sample.humidity > FALLBACK_FOREST_HUMID_MIN {
    @biome.Forest
  } else {
    @biome.Plains
  }
}

///|
fn fallback_dry_land_biome(sample : @biome.BiomeSample) -> @biome.Biome {
  if sample.temperature > FALLBACK_DESERT_TEMP_THRESHOLD &&
    sample.humidity < FALLBACK_DESERT_HUMID_MAX {
    @biome.Desert
  } else if sample.humidity > FALLBACK_FOREST_HUMID_MIN {
    @biome.Forest
  } else {
    @biome.Plains
  }
}

///|
fn terrain_biome_for_height(
  sample : @biome.BiomeSample,
  surface_biome : @biome.Biome,
) -> @biome.Biome {
  match surface_biome {
    @biome.River | @biome.FrozenRiver => fallback_dry_land_biome(sample)
    @biome.DesertLakes => @biome.Desert
    _ => surface_biome
  }
}

///|
fn water_height_hint(sample : @biome.BiomeSample) -> Double {
  let erosion_t = clamp01((sample.erosion + 1.0) * 0.5)
  let continental_lift = if sample.continental < 0.0 {
    sample.continental * 20.0
  } else {
    sample.continental * 48.0
  }
  SEA_LEVEL.to_double() +
  2.0 +
  continental_lift +
  (1.0 - erosion_t) * 7.0 +
  sample.ridge * 24.0 +
  sample.weirdness.abs() * 5.0
}

///|
fn water_context_factor(sample : @biome.BiomeSample) -> Double {
  let hint = water_height_hint(sample)
  let near_sea = clamp01((WATER_CONTEXT_MAX_HINT - hint) / WATER_CONTEXT_FADE)
  let rugged = clamp01(sample.ridge * 1.25 + max0(sample.continental) * 0.95 - 0.70)
  clamp01(near_sea * (1.0 - rugged))
}

///|
fn surface_biome_from_column(
  world : World,
  sample : @biome.BiomeSample,
  biome : @biome.Biome,
) -> @biome.Biome {
  if world.kind is WorldType::Infinite &&
    (biome is @biome.Ocean || biome is @biome.DeepOcean) &&
    water_context_factor(sample) < WATER_CONTEXT_ENABLE_THRESHOLD {
    fallback_land_biome(sample)
  } else {
    biome
  }
}

///|
fn plain_height_with_biome(
  world : World,
  wx : Int,
  wz : Int,
  sample : @biome.BiomeSample,
  biome : @biome.Biome,
  params : @biome.BiomeParams,
) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let noise = world.noise
  let erosion_t = clamp01((sample.erosion + 1.0) * 0.5)
  let continental_lift = if sample.continental < 0.0 {
    sample.continental * 26.0
  } else {
    sample.continental * 42.0
  }
  let macro_hill = @biome.fbm2d(noise, x * HILL_FREQ, z * HILL_FREQ, 4, 2.0, 0.5)
    .abs() *
    HILL_AMP
  let plains_wave = if biome is @biome.Ocean ||
    biome is @biome.DeepOcean ||
    biome is @biome.River ||
    biome is @biome.FrozenRiver {
    0.0
  } else {
    let warp_x = noise.gen2d(x * PLAINS_WARP_FREQ, z * PLAINS_WARP_FREQ) *
      PLAINS_WARP_AMP
    let warp_z = noise.gen2d(
        (x + 401.0) * PLAINS_WARP_FREQ,
        (z - 397.0) * PLAINS_WARP_FREQ,
      ) *
      PLAINS_WARP_AMP
    @biome.fbm2d(
      noise,
      (x + warp_x) * PLAINS_WAVE_FREQ,
      (z + warp_z) * PLAINS_WAVE_FREQ,
      3,
      2.0,
      0.5,
    ) *
    PLAINS_WAVE_AMP
  }
  let climate_shift = sample.humidity * 0.7 - sample.temperature.abs() * 0.35
  let height = SEA_LEVEL.to_double() +
    params.base_offset +
    continental_lift +
    (1.0 - erosion_t) * 5.5 +
    macro_hill +
    plains_wave +
    climate_shift
  let h = height.round().to_int()
  let min_h = MIN_TERRAIN_HEIGHT + 2
  let max_h = if params.max_height - 6 < min_h {
    min_h
  } else {
    params.max_height - 6
  }
  if h < min_h {
    min_h
  } else if h > max_h {
    max_h
  } else {
    h
  }
}

///|
fn surface_height_with_params(
  world : World,
  wx : Int,
  wz : Int,
  sample : @biome.BiomeSample,
  biome : @biome.Biome,
) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let noise = world.noise
  let surface_biome = surface_biome_from_column(world, sample, biome)
  let terrain_biome = terrain_biome_for_height(sample, surface_biome)
  let surface_params = @biome.params(terrain_biome)
  let surface_plain = plain_height_with_biome(
    world,
    wx,
    wz,
    sample,
    terrain_biome,
    surface_params,
  )
  let mut height = surface_plain.to_double()
  if terrain_biome is @biome.Ocean || terrain_biome is @biome.DeepOcean {
    let seabed = @biome.fbm2d(noise, x * 0.012, z * 0.012, 3, 2.0, 0.5).abs() * 3.5
    if terrain_biome is @biome.DeepOcean {
      height = height - seabed * 1.8
    } else {
      height = height - seabed
    }
  } else {
    let warp_x = noise.gen2d(x * MOUNTAIN_WARP_FREQ, z * MOUNTAIN_WARP_FREQ) *
      MOUNTAIN_WARP_AMP
    let warp_z = noise.gen2d(
        (x + 911.0) * MOUNTAIN_WARP_FREQ,
        (z - 733.0) * MOUNTAIN_WARP_FREQ,
      ) *
      MOUNTAIN_WARP_AMP
    let ridge_a = 1.0 -
      @biome
        .fbm2d(
          noise,
          (x + warp_x) * MOUNTAIN_RIDGE_FREQ_A,
          (z + warp_z) * MOUNTAIN_RIDGE_FREQ_A,
          4,
          2.0,
          0.5,
        )
        .abs()
    let ridge_b = 1.0 -
      @biome
        .fbm2d(
          noise,
          (x - warp_z * 0.35) * MOUNTAIN_RIDGE_FREQ_B,
          (z + warp_x * 0.35) * MOUNTAIN_RIDGE_FREQ_B,
          3,
          2.0,
          0.5,
        )
        .abs()
    let ridge = clamp01(ridge_a * 0.68 + ridge_b * 0.32)
    let peaks = @biome.fbm2d(noise, x * PV_FREQ, z * PV_FREQ, 3, 2.0, 0.5).abs()
    let mountain_signal =
      sample.ridge * 1.34 + peaks * 0.26 + max0(sample.continental) * 0.18 -
      0.86
    let foothill_mask = smoothstep(0.08, 0.42, mountain_signal)
    let mountain_mask = smoothstep(0.30, 0.92, mountain_signal)
    let erosion_t = clamp01((sample.erosion + 1.0) * 0.5)
    let ridged_shape = clamp01(ridge * 0.72 + sample.ridge * 0.28)
    let biome_uplift = if terrain_biome is @biome.Mountains ||
      terrain_biome is @biome.WindsweptHills {
      1.0
    } else if terrain_biome is @biome.Forest {
      0.58
    } else {
      0.48
    }
    let foothill = foothill_mask *
      (1.0 - mountain_mask) *
      surface_params.mountain_amp *
      (0.11 + ridged_shape * 0.10)
    let mountain_shape = mountain_mask * (0.55 + mountain_mask * 0.45)
    let mountain_core = mountain_shape *
      (ridged_shape * ridged_shape * 0.86 + ridged_shape * 0.14) *
      surface_params.mountain_amp *
      (0.50 + (1.0 - erosion_t) * 0.82) *
      biome_uplift
    let jagged = noise.gen2d((x - warp_x) * 0.024, (z + warp_z) * 0.024) *
      (foothill_mask * 0.45 + mountain_mask * 0.55) *
      1.45
    let river_t = clamp01((RIVER_CARVE_WIDTH - sample.river) / RIVER_CARVE_WIDTH)
    let river_strength = if surface_biome is @biome.Beach {
      surface_params.river_carve.to_double() * 0.22
    } else {
      0.0
    }
    let river_carve = river_t * river_t * river_strength
    height = height + foothill + mountain_core + jagged - river_carve
  }
  if surface_biome is @biome.Beach {
    let beach_cap = SEA_LEVEL.to_double() + 2.0
    if height > beach_cap {
      height = beach_cap
    }
  } else if surface_biome is @biome.Ocean {
    let ocean_cap = SEA_LEVEL.to_double() - 5.0
    if height > ocean_cap {
      height = ocean_cap
    }
  } else if surface_biome is @biome.DeepOcean {
    let deep_ocean_cap = SEA_LEVEL.to_double() - 15.0
    if height > deep_ocean_cap {
      height = deep_ocean_cap
    }
  }
  let h = height.round().to_int()
  let max_h = if surface_params.max_height > MAX_TERRAIN_HEIGHT {
    MAX_TERRAIN_HEIGHT
  } else {
    surface_params.max_height
  }
  if h < MIN_TERRAIN_HEIGHT {
    MIN_TERRAIN_HEIGHT
  } else if h > max_h {
    max_h
  } else {
    h
  }
}

///|
pub fn surface_height(world : World, wx : Int, wz : Int) -> Int {
  let sample = @biome.sample(world.noise, wx, wz)
  let biome = @biome.biome_from_sample(sample)
  surface_height_with_params(world, wx, wz, sample, biome)
}

///|
fn terrain_column(world : World, wx : Int, wz : Int) -> TerrainColumn {
  let sample = @biome.sample(world.noise, wx, wz)
  let biome = @biome.biome_from_sample(sample)
  let surface_biome = surface_biome_from_column(world, sample, biome)
  let params = @biome.params(surface_biome)
  let plain = plain_height_with_biome(
    world,
    wx,
    wz,
    sample,
    surface_biome,
    params,
  )
  let surface = surface_height_with_params(world, wx, wz, sample, surface_biome)
  TerrainColumn::{ wx, wz, sample, biome, surface_biome, plain, surface }
}

///|
fn surface_dirt_depth(world : World, wx : Int, wz : Int) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let detail = world.noise.gen2d(x / DETAIL_SCALE, z / DETAIL_SCALE).abs()
  3 + (detail * 2.5).floor().to_int()
}

///|
fn desert_sand_depth(world : World, wx : Int, wz : Int) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let t = world.noise.gen2d(x / DESERT_SAND_SCALE, z / DESERT_SAND_SCALE).abs()
  DESERT_SAND_DEPTH_MIN +
  (t * (DESERT_SAND_DEPTH_MAX - DESERT_SAND_DEPTH_MIN).to_double())
  .floor()
  .to_int()
}

///|
fn density_at_column(world : World, column : TerrainColumn, wy : Int) -> Double {
  let x = column.wx.to_double()
  let y = wy.to_double()
  let z = column.wz.to_double()
  let sample = column.sample
  let biome = column.surface_biome
  let surface = column.surface.to_double()
  let plain = column.plain.to_double()
  if y > surface {
    -1.0
  } else if y <= WORLD_MIN_Y.to_double() + 1.0 {
    1.0
  } else {
    let vertical = surface - y
    let cave_cheese = world.noise.gen3d(x * CAVE_FREQ, y * CAVE_FREQ, z * CAVE_FREQ).abs()
    let cave_spaghetti = world.noise
      .gen3d((x + 313.0) * 0.062, y * 0.073, (z - 719.0) * 0.062)
      .abs()
    let cave_noodle = world.noise
      .gen3d((x - 991.0) * 0.087, y * 0.091, (z + 557.0) * 0.087)
      .abs()
    let cave_mix = cave_cheese * 0.55 + cave_spaghetti * 0.32 + cave_noodle * 0.23
    let cave_threshold = CAVE_THRESHOLD + sample.erosion * 0.02
    let cave_region = world.noise
      .gen3d((x + 557.0) * CAVE_REGION_FREQ, y * CAVE_REGION_FREQ, (z - 881.0) * CAVE_REGION_FREQ)
    let cave_limit = if biome is @biome.Ocean ||
      biome is @biome.DeepOcean ||
      biome is @biome.River ||
      biome is @biome.FrozenRiver {
      surface - 22.0
    } else {
      surface - 16.0
    }
    let sea_guard = SEA_LEVEL.to_double() - 8.0
    let final_cave_limit = if cave_limit < sea_guard {
      cave_limit
    } else {
      sea_guard
    }
    if y < final_cave_limit &&
      cave_mix < cave_threshold &&
      cave_region > CAVE_REGION_THRESHOLD {
      -1.0
    } else {
      let overhang = world.noise
        .gen3d(
          (x + 113.0) * TERRAIN_3D_FREQ,
          y * TERRAIN_3D_FREQ,
          (z - 83.0) * TERRAIN_3D_FREQ,
        )
      let carve = overhang.abs() * (TERRAIN_3D_AMP + sample.weirdness * 1.3)
      let mut density = vertical
      if y > plain + 2.0 {
        density = density - carve
      }
      if biome is @biome.Mountains || biome is @biome.WindsweptHills {
        let cliff = world.noise.gen3d(x * 0.040, y * 0.022, z * 0.040)
        let weather = world.noise
          .gen3d((x + 211.0) * 0.018, y * 0.012, (z - 377.0) * 0.018)
          .abs()
        density = density + cliff * 1.45 - weather * 0.95
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
pub fn World::new(
  seed? : UInt64 = @env.now(),
  world_type? : WorldType = WorldType::PreClassic,
) -> World {
  let noise = @util.PerlinNoise::new(seed~)
  World::{ seed, kind: world_type, noise }
}

///|
pub fn World::min_y(self : World) -> Int {
  match self.kind {
    WorldType::Finite => FINITE_MIN_Y
    WorldType::PreClassic => PRECLASSIC_MIN_Y
    _ => WORLD_MIN_Y
  }
}

///|
pub fn World::max_y(self : World) -> Int {
  match self.kind {
    WorldType::Finite => FINITE_MAX_Y
    WorldType::PreClassic => PRECLASSIC_MAX_Y
    _ => WORLD_MAX_Y
  }
}

///|
fn fill_air(chunk : Chunk) -> Chunk {
  let air = @block.AIR_LONG_ID
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      for ry in 0..<CHUNK_Y_SIZE {
        chunk.update_tile_map(rx, ry, rz, air)
      }
    }
  }
  chunk
}

///|
pub fn World::generate_chunk(
  world : World,
  chunk_x : Int,
  chunk_y : Int,
  chunk_z : Int,
) -> Chunk {
  let chunk = Chunk::new(chunk_x, chunk_y, chunk_z)
  match world.kind {
    WorldType::Flat => fill_flat(chunk)
    WorldType::Infinite => fill_infinite(world, chunk)
    WorldType::PreClassic =>
      if is_chunk_in_preclassic_world(chunk_x, chunk_y, chunk_z) {
        fill_preclassic(world, chunk)
      } else {
        fill_air(chunk)
      }
    WorldType::Finite =>
      if is_chunk_in_finite_world(chunk_x, chunk_y, chunk_z) {
        fill_finite(world, chunk)
      } else {
        fill_air(chunk)
      }
  }
}
