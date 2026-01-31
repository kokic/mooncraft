///|
pub struct World {
  seed : UInt64
  world_type : WorldType
  noise : @util.PerlinNoise
}

///|
/// Pre-classic bottom layer Y (bedrock).
pub const PRECLASSIC_MIN_Y : Int = -32

///|
/// Highest world Y (fixed for now).
pub const WORLD_MAX_Y : Int = 32

///|
/// Lowest world Y (player view).
pub const WORLD_MIN_Y : Int = PRECLASSIC_MIN_Y - 32

///|
/// Hard floor for terrain height; higher => raises lowest land.
const MIN_TERRAIN_HEIGHT : Int = 0

///|
/// Reserved global cap for terrain height; higher => allows taller peaks.
const MAX_TERRAIN_HEIGHT : Int = 127

///|
/// Sea level baseline; higher => more land submerged.
const SEA_LEVEL : Int = 8

///|
/// Detail noise scale for dirt thickness; higher => smoother soil variation.
const DETAIL_SCALE : Double = 22.0

///|
/// Peak/valley noise frequency; higher => more frequent ridges.
const PV_FREQ : Double = 0.015

///|
/// Plains micro-variation frequency; higher => shorter flat spans.
const PLAINS_WAVE_FREQ : Double = 0.01

///|
/// Plains micro-variation amplitude; higher => more visible undulation.
const PLAINS_WAVE_AMP : Double = 1.6

///|
/// Plains domain warp frequency; higher => more irregular contours.
const PLAINS_WARP_FREQ : Double = 0.006

///|
/// Plains domain warp amplitude; higher => stronger warp.
const PLAINS_WARP_AMP : Double = 18.0

///|
/// 3D carve noise frequency; higher => more small caves/voids.
const TERRAIN_3D_FREQ : Double = 0.02

///|
/// 3D carve amplitude; higher => more aggressive carving.
const TERRAIN_3D_AMP : Double = 2.0

///|
/// Cave noise frequency; higher => denser cave networks.
const CAVE_FREQ : Double = 0.045

///|
/// Cave threshold; higher => fewer caves, lower => more caves.
const CAVE_THRESHOLD : Double = 0.28

///|
/// Desert sand minimum depth; higher => thicker sand layers.
const DESERT_SAND_DEPTH_MIN : Int = 4

///|
/// Desert sand maximum depth; higher => thicker sand variation.
const DESERT_SAND_DEPTH_MAX : Int = 6

///|
/// Desert sand noise scale; higher => smoother sand depth changes.
const DESERT_SAND_SCALE : Double = 30.0

///|
/// Desert sandstone depth; higher => thicker sandstone layer.
const DESERT_SANDSTONE_DEPTH : Int = 4

///|
/// Base (flat) height per biome, before mountain shaping.
fn plain_height(world : World, wx : Int, wz : Int) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let noise = world.noise
  let biome = @biome.biome_at(noise, wx, wz)
  let params = @biome.params(biome)
  let continental = @biome.fbm2d(
    noise,
    x * @biome.CONTINENTAL_FREQ,
    z * @biome.CONTINENTAL_FREQ,
    4,
    2.0,
    0.5,
  )
  let base = SEA_LEVEL.to_double() + continental * 6.0
  let plains_wave = if biome is @biome.Plains {
    let warp_x = noise.gen2d(x * PLAINS_WARP_FREQ, z * PLAINS_WARP_FREQ) *
      PLAINS_WARP_AMP
    let warp_z = noise.gen2d(
        (x + 400.0) * PLAINS_WARP_FREQ,
        (z - 400.0) * PLAINS_WARP_FREQ,
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
  } else {
    0.0
  }
  let height = base + params.base_offset + plains_wave
  let h = height.round().to_int()
  let base_shift = params.base_offset.round().to_int()
  let min_h = 5 + base_shift
  let max_h = 15 + base_shift
  if h < min_h {
    min_h
  } else if h > max_h {
    max_h
  } else {
    h
  }
}

///|
/// Surface height with biome-aware mountain shaping and erosion.
fn surface_height(world : World, wx : Int, wz : Int) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let noise = world.noise
  let biome = @biome.biome_at(noise, wx, wz)
  let params = @biome.params(biome)
  let erosion = @biome.fbm2d(
    noise,
    x * @biome.EROSION_FREQ,
    z * @biome.EROSION_FREQ,
    3,
    2.0,
    0.5,
  )
  let peaks = @biome.fbm2d(noise, x * PV_FREQ, z * PV_FREQ, 3, 2.0, 0.5).abs()
  let erosion_t = (erosion + 1.0) / 2.0
  let ridge = peaks * peaks * peaks
  let mountain = ridge * params.mountain_amp * (1.0 - erosion_t * 0.6)
  let height = plain_height(world, wx, wz).to_double() + mountain
  let h = height.round().to_int()
  let max_h = if params.max_height > MAX_TERRAIN_HEIGHT {
    MAX_TERRAIN_HEIGHT
  } else {
    params.max_height
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
/// Dirt depth varies by low-frequency detail noise.
fn surface_dirt_depth(world : World, wx : Int, wz : Int) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let detail = world.noise.gen2d(x / DETAIL_SCALE, z / DETAIL_SCALE).abs()
  3 + (detail * 2.0).floor().to_int()
}

///|
/// Desert sand depth varies smoothly across the desert.
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
/// Density field used to decide air vs solid for pre-classic terrain.
fn density_at(world : World, wx : Int, wy : Int, wz : Int) -> Double {
  let x = wx.to_double()
  let y = wy.to_double()
  let z = wz.to_double()
  let biome = @biome.biome_at(world.noise, wx, wz)
  let surface = surface_height(world, wx, wz).to_double()
  let plain = plain_height(world, wx, wz).to_double()
  if y > surface {
    -1.0
  } else if y <= plain {
    if biome is @biome.Mountains {
      1.0
    } else {
      let cave = world.noise
        .gen3d(x * CAVE_FREQ, y * CAVE_FREQ, z * CAVE_FREQ)
        .abs()
      if y < surface - 6.0 && cave < CAVE_THRESHOLD {
        -1.0
      } else {
        1.0
      }
    }
  } else if biome is @biome.Mountains {
    surface - y
  } else {
    let carve = world.noise
      .gen3d(x * TERRAIN_3D_FREQ, y * TERRAIN_3D_FREQ, z * TERRAIN_3D_FREQ)
      .abs() *
      TERRAIN_3D_AMP
    let mut density = surface - y
    if y > plain + 3.0 {
      density = density - carve
    }
    if density <= 0.0 {
      -1.0
    } else {
      density
    }
  }
}

///|
/// Create a world with noise seeded by time by default.
pub fn World::new(
  seed? : UInt64 = @env.now(),
  world_type? : WorldType = WorldType::PreClassic,
) -> World {
  let noise = @util.PerlinNoise::new(seed~)
  World::{ seed, world_type, noise }
}

///|
/// Generate a chunk based on the configured world type.
pub fn World::generate_chunk(
  self : World,
  chunk_x : Int,
  chunk_y : Int,
  chunk_z : Int,
) -> Chunk {
  let chunk = Chunk::new(chunk_x, chunk_y, chunk_z)
  match self.world_type {
    WorldType::Flat => fill_flat(chunk)
    WorldType::PreClassic => fill_pre_classic(self, chunk)
  }
}
