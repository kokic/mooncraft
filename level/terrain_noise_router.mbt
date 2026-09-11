///|
/// Seeded noise sources used by modern Infinite terrain. Fixed salts make each
/// channel deterministic while keeping climate, density, caves, and aquifers
/// statistically independent.
pub struct TerrainNoiseRouter {
  temperature : @util.PerlinNoise
  humidity : @util.PerlinNoise
  continentalness : @util.PerlinNoise
  erosion : @util.PerlinNoise
  weirdness : @util.PerlinNoise
  ridges : @util.PerlinNoise
  river : @util.PerlinNoise
  surface : @util.PerlinNoise
  detail : @util.PerlinNoise
  terrain_shape : @util.PerlinNoise
  terrain_ridge : @util.PerlinNoise
  cave_region : @util.PerlinNoise
  cave_cheese : @util.PerlinNoise
  cave_spaghetti_a : @util.PerlinNoise
  cave_spaghetti_b : @util.PerlinNoise
  cave_noodle_a : @util.PerlinNoise
  cave_noodle_b : @util.PerlinNoise
  aquifer_level : @util.PerlinNoise
  aquifer_barrier : @util.PerlinNoise
  aquifer_lava : @util.PerlinNoise
}

///|
fn salted_seed(seed : UInt, salt : UInt) -> UInt {
  let mut value = seed ^ salt
  value = (value ^ (value >> 16)) * 0x7feb352dU
  value = (value ^ (value >> 15)) * 0x846ca68bU
  value ^ (value >> 16)
}

///|
fn TerrainNoiseRouter::new(seed : UInt) -> TerrainNoiseRouter {
  let source = fn(salt : UInt) -> @util.PerlinNoise {
    @util.PerlinNoise::new(seed=salted_seed(seed, salt))
  }
  {
    temperature: source(0x01U),
    humidity: source(0x02U),
    continentalness: source(0x03U),
    erosion: source(0x04U),
    weirdness: source(0x05U),
    ridges: source(0x06U),
    river: source(0x07U),
    surface: source(0x08U),
    detail: source(0x09U),
    terrain_shape: source(0x0aU),
    terrain_ridge: source(0x0bU),
    cave_region: source(0x0cU),
    cave_cheese: source(0x0dU),
    cave_spaghetti_a: source(0x0eU),
    cave_spaghetti_b: source(0x0fU),
    cave_noodle_a: source(0x10U),
    cave_noodle_b: source(0x11U),
    aquifer_level: source(0x12U),
    aquifer_barrier: source(0x13U),
    aquifer_lava: source(0x14U),
  }
}

///|
fn TerrainNoiseRouter::sample_climate(
  self : TerrainNoiseRouter,
  wx : Int,
  wz : Int,
) -> @biome.BiomeSample {
  let x = wx.to_double()
  let z = wz.to_double()
  let fbm = fn(
    noise : @util.PerlinNoise,
    frequency : Double,
    octaves : Int,
  ) -> Double {
    @biome.fbm2d(noise, x * frequency, z * frequency, octaves, 2.0, 0.5)
  }
  let ridge_a = 1.0 - fbm(self.ridges, @biome.RIDGE_FREQ_A, 4).abs()
  let ridge_b = 1.0 -
    @biome.fbm2d(
      self.ridges,
      (x - 977.0) * @biome.RIDGE_FREQ_B,
      (z + 641.0) * @biome.RIDGE_FREQ_B,
      3,
      2.0,
      0.5,
    ).abs()
  {
    temperature: fbm(self.temperature, @biome.TEMP_FREQ, 4),
    humidity: fbm(self.humidity, @biome.HUMIDITY_FREQ, 4),
    continental: fbm(self.continentalness, @biome.CONTINENTAL_FREQ, 4),
    erosion: fbm(self.erosion, @biome.EROSION_FREQ, 3),
    weirdness: fbm(self.weirdness, @biome.WEIRDNESS_FREQ, 4),
    ridge: @util.clamp01(ridge_a * 0.7 + ridge_b * 0.3),
    river: fbm(self.river, @biome.RIVER_FREQ, 3).abs(),
  }
}
