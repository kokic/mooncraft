///|
/// Seeded noise sources used by modern Infinite terrain. Fixed salts make each
/// channel deterministic while keeping climate, density, caves, and aquifers
/// statistically independent.
pub struct TerrainNoiseRouter {
  temperature : ClimateNoise
  humidity : ClimateNoise
  continentalness : ClimateNoise
  erosion : ClimateNoise
  weirdness : ClimateNoise
  shift : ClimateNoise
  jagged : ClimateNoise
  detail : @util.PerlinNoise
  terrain : TerrainBlendedNoise
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
  let source = (salt : UInt) => {
    @util.PerlinNoise::new(seed=salted_seed(seed, salt))
  }
  {
    temperature: ClimateNoise::new(seed, 0x01U, 1.0 / 1024.0, [
      1.5, 0.0, 1.0, 0.0, 0.0, 0.0,
    ]),
    humidity: ClimateNoise::new(seed, 0x02U, 1.0 / 256.0, [
      1.0, 1.0, 0.0, 0.0, 0.0, 0.0,
    ]),
    continentalness: ClimateNoise::new(seed, 0x03U, 1.0 / 512.0, [
      1.0, 1.0, 2.0, 2.0, 2.0, 1.0, 1.0, 1.0, 1.0,
    ]),
    erosion: ClimateNoise::new(seed, 0x04U, 1.0 / 512.0, [
      1.0, 1.0, 0.0, 1.0, 1.0,
    ]),
    weirdness: ClimateNoise::new(seed, 0x05U, 1.0 / 128.0, [
      1.0, 2.0, 1.0, 0.0, 0.0, 0.0,
    ]),
    shift: ClimateNoise::new(seed, 0x06U, 1.0 / 8.0, [1.0, 1.0, 1.0, 0.0]),
    jagged: ClimateNoise::new(seed, 0x08U, 1500.0 / 65536.0, [
      1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
      1.0,
    ]),
    detail: source(0x09U),
    terrain: TerrainBlendedNoise::new(seed),
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
  let x = wx.to_double() * 0.25
  let z = wz.to_double() * 0.25
  let shifted_x = x + self.shift.sample(x, z) * 4.0
  let shifted_z = z + self.shift.sample(z + 103.0, x - 71.0) * 4.0
  let weirdness = self.weirdness.sample(shifted_x, shifted_z)
  let peaks_and_valleys = -((weirdness.abs() - 2.0 / 3.0).abs() - 1.0 / 3.0) *
    3.0
  {
    temperature: self.temperature.sample(shifted_x, shifted_z),
    humidity: self.humidity.sample(shifted_x, shifted_z),
    continental: self.continentalness.sample(shifted_x, shifted_z),
    erosion: self.erosion.sample(shifted_x, shifted_z),
    weirdness,
    ridge: peaks_and_valleys,
    river: weirdness.abs(),
  }
}
