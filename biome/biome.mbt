///|
pub(all) enum Biome {
  Plains
  Forest
  Mountains
  WindsweptHills
  Desert
  DesertLakes
  Beach
  River
  FrozenRiver
  Ocean
  DeepOcean
}

///|
/// Controls overall biome size; higher => biomes change more frequently.
pub const BIOME_FREQ : Double = 0.0019

///|
pub const TEMP_FREQ : Double = BIOME_FREQ

///|
pub const HUMIDITY_FREQ : Double = BIOME_FREQ

///|
/// Controls continental drift scale; lower => larger landmass variation.
pub const CONTINENTAL_FREQ : Double = 0.0012

///|
pub const EROSION_FREQ : Double = 0.0021

///|
pub const WEIRDNESS_FREQ : Double = 0.0046

///|
pub const RIVER_FREQ : Double = 0.0032

///|
pub const RIDGE_FREQ_A : Double = 0.0068

///|
pub const RIDGE_FREQ_B : Double = 0.014

///|
const DEEP_OCEAN_CONTINENTAL_MAX : Double = -0.95

///|
const OCEAN_CONTINENTAL_MAX : Double = -0.86

///|
const BEACH_CONTINENTAL_MAX : Double = -0.60

///|
const DESERT_TEMP_THRESHOLD : Double = 0.30

///|
const DESERT_HUMID_THRESHOLD : Double = 0.02

///|
const FOREST_HUMID_THRESHOLD : Double = 0.0

///|
const MOUNTAIN_SCORE_THRESHOLD : Double = 0.85

///|
const WINDSWEPT_SCORE_THRESHOLD : Double = 0.46

///|
const DESERT_LAKES_EROSION_THRESHOLD : Double = 0.08

///|
const PLAINS_BASE_OFFSET : Double = 3.0

///|
const FOREST_BASE_OFFSET : Double = 4.0

///|
const MOUNTAIN_BASE_OFFSET : Double = 12.0

///|
const WINDSWEPT_BASE_OFFSET : Double = 8.0

///|
const DESERT_BASE_OFFSET : Double = 2.0

///|
const DESERT_LAKES_BASE_OFFSET : Double = 0.0

///|
const BEACH_BASE_OFFSET : Double = -2.0

///|
const RIVER_BASE_OFFSET : Double = -1.8

///|
const FROZEN_RIVER_BASE_OFFSET : Double = -1.8

///|
const OCEAN_BASE_OFFSET : Double = -6.0

///|
const DEEP_OCEAN_BASE_OFFSET : Double = -12.0

///|
const PLAINS_MOUNTAIN_AMP : Double = 14.0

///|
const FOREST_MOUNTAIN_AMP : Double = 15.0

///|
const MOUNTAIN_MOUNTAIN_AMP : Double = 58.0

///|
const WINDSWEPT_MOUNTAIN_AMP : Double = 34.0

///|
const DESERT_MOUNTAIN_AMP : Double = 11.0

///|
const DESERT_LAKES_MOUNTAIN_AMP : Double = 10.0

///|
const BEACH_MOUNTAIN_AMP : Double = 2.0

///|
const RIVER_MOUNTAIN_AMP : Double = 3.0

///|
const FROZEN_RIVER_MOUNTAIN_AMP : Double = 3.0

///|
const OCEAN_MOUNTAIN_AMP : Double = 1.4

///|
const DEEP_OCEAN_MOUNTAIN_AMP : Double = 1.4

///|
const PLAINS_MAX_HEIGHT : Int = 126

///|
const FOREST_MAX_HEIGHT : Int = 126

///|
const MOUNTAIN_MAX_HEIGHT : Int = 127

///|
const WINDSWEPT_MAX_HEIGHT : Int = 127

///|
const DESERT_MAX_HEIGHT : Int = 122

///|
const DESERT_LAKES_MAX_HEIGHT : Int = 118

///|
const BEACH_MAX_HEIGHT : Int = 72

///|
const RIVER_MAX_HEIGHT : Int = 72

///|
const FROZEN_RIVER_MAX_HEIGHT : Int = 72

///|
const OCEAN_MAX_HEIGHT : Int = 62

///|
const DEEP_OCEAN_MAX_HEIGHT : Int = 56

///|
pub(all) struct BiomeSample {
  temperature : Double
  humidity : Double
  continental : Double
  erosion : Double
  weirdness : Double
  ridge : Double
  river : Double
}

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
pub fn fbm2d(
  noise : @util.PerlinNoise,
  x : Double,
  z : Double,
  octaves : Int,
  lacunarity : Double,
  gain : Double,
) -> Double {
  let mut freq = 1.0
  let mut amp = 1.0
  let mut sum = 0.0
  let mut norm = 0.0
  for _ in 0..<octaves {
    sum = sum + noise.gen2d(x * freq, z * freq) * amp
    norm = norm + amp
    freq = freq * lacunarity
    amp = amp * gain
  }
  if norm == 0.0 {
    0.0
  } else {
    sum / norm
  }
}

///|
pub fn sample(noise : @util.PerlinNoise, wx : Int, wz : Int) -> BiomeSample {
  let x = wx.to_double()
  let z = wz.to_double()
  let temperature = fbm2d(noise, x * TEMP_FREQ, z * TEMP_FREQ, 4, 2.0, 0.5)
  let humidity = fbm2d(
    noise,
    (x + 1337.0) * HUMIDITY_FREQ,
    (z - 2111.0) * HUMIDITY_FREQ,
    4,
    2.0,
    0.5,
  )
  let continental = fbm2d(
    noise,
    (x - 809.0) * CONTINENTAL_FREQ,
    (z + 613.0) * CONTINENTAL_FREQ,
    4,
    2.0,
    0.5,
  )
  let erosion = fbm2d(
    noise,
    (x + 3791.0) * EROSION_FREQ,
    (z - 1523.0) * EROSION_FREQ,
    3,
    2.0,
    0.5,
  )
  let weirdness = fbm2d(
    noise,
    (x - 521.0) * WEIRDNESS_FREQ,
    (z + 937.0) * WEIRDNESS_FREQ,
    4,
    2.0,
    0.5,
  )
  let ridge_a = 1.0 -
    fbm2d(
      noise,
      (x + 137.0) * RIDGE_FREQ_A,
      (z - 89.0) * RIDGE_FREQ_A,
      4,
      2.0,
      0.5,
    ).abs()
  let ridge_b = 1.0 -
    fbm2d(
      noise,
      (x - 977.0) * RIDGE_FREQ_B,
      (z + 641.0) * RIDGE_FREQ_B,
      3,
      2.0,
      0.5,
    ).abs()
  let ridge = clamp01(ridge_a * 0.7 + ridge_b * 0.3)
  let river = fbm2d(
    noise,
    (x + 7777.0) * RIVER_FREQ,
    (z - 3333.0) * RIVER_FREQ,
    3,
    2.0,
    0.5,
  ).abs()
  BiomeSample::{ temperature, humidity, continental, erosion, weirdness, ridge, river }
}

///|
fn mountain_score(sample : BiomeSample) -> Double {
  let erosion_t = clamp01((sample.erosion + 1.0) * 0.5)
  sample.ridge * (1.20 - erosion_t * 0.60) +
  sample.weirdness.abs() * 0.14 +
  max0(sample.continental) * 0.18
}

///|
pub fn biome_from_sample(sample : BiomeSample) -> Biome {
  if sample.continental < DEEP_OCEAN_CONTINENTAL_MAX {
    DeepOcean
  } else if sample.continental < OCEAN_CONTINENTAL_MAX {
    Ocean
  } else if sample.continental < BEACH_CONTINENTAL_MAX {
    Beach
  } else {
    let m_score = mountain_score(sample)
    if m_score > MOUNTAIN_SCORE_THRESHOLD && sample.continental > 0.06 {
      Mountains
    } else if m_score > WINDSWEPT_SCORE_THRESHOLD &&
      sample.continental > -0.10 &&
      sample.erosion < 0.02 {
      WindsweptHills
    } else if sample.temperature > DESERT_TEMP_THRESHOLD &&
      sample.humidity < DESERT_HUMID_THRESHOLD {
      if sample.erosion > DESERT_LAKES_EROSION_THRESHOLD &&
        sample.continental < 0.28 {
        DesertLakes
      } else {
        Desert
      }
    } else if sample.humidity > FOREST_HUMID_THRESHOLD {
      Forest
    } else {
      Plains
    }
  }
}

///|
pub fn biome_at(noise : @util.PerlinNoise, wx : Int, wz : Int) -> Biome {
  biome_from_sample(sample(noise, wx, wz))
}

///|
pub struct BiomeParams {
  base_offset : Double
  mountain_amp : Double
  max_height : Int
  river_carve : Int
}

///|
pub fn params(biome : Biome) -> BiomeParams {
  match biome {
    Plains =>
      BiomeParams::{
        base_offset: PLAINS_BASE_OFFSET,
        mountain_amp: PLAINS_MOUNTAIN_AMP,
        max_height: PLAINS_MAX_HEIGHT,
        river_carve: 3,
      }
    Forest =>
      BiomeParams::{
        base_offset: FOREST_BASE_OFFSET,
        mountain_amp: FOREST_MOUNTAIN_AMP,
        max_height: FOREST_MAX_HEIGHT,
        river_carve: 3,
      }
    Mountains =>
      BiomeParams::{
        base_offset: MOUNTAIN_BASE_OFFSET,
        mountain_amp: MOUNTAIN_MOUNTAIN_AMP,
        max_height: MOUNTAIN_MAX_HEIGHT,
        river_carve: 4,
      }
    WindsweptHills =>
      BiomeParams::{
        base_offset: WINDSWEPT_BASE_OFFSET,
        mountain_amp: WINDSWEPT_MOUNTAIN_AMP,
        max_height: WINDSWEPT_MAX_HEIGHT,
        river_carve: 4,
      }
    Desert =>
      BiomeParams::{
        base_offset: DESERT_BASE_OFFSET,
        mountain_amp: DESERT_MOUNTAIN_AMP,
        max_height: DESERT_MAX_HEIGHT,
        river_carve: 2,
      }
    DesertLakes =>
      BiomeParams::{
        base_offset: DESERT_LAKES_BASE_OFFSET,
        mountain_amp: DESERT_LAKES_MOUNTAIN_AMP,
        max_height: DESERT_LAKES_MAX_HEIGHT,
        river_carve: 5,
      }
    Beach =>
      BiomeParams::{
        base_offset: BEACH_BASE_OFFSET,
        mountain_amp: BEACH_MOUNTAIN_AMP,
        max_height: BEACH_MAX_HEIGHT,
        river_carve: 6,
      }
    River =>
      BiomeParams::{
        base_offset: RIVER_BASE_OFFSET,
        mountain_amp: RIVER_MOUNTAIN_AMP,
        max_height: RIVER_MAX_HEIGHT,
        river_carve: 10,
      }
    FrozenRiver =>
      BiomeParams::{
        base_offset: FROZEN_RIVER_BASE_OFFSET,
        mountain_amp: FROZEN_RIVER_MOUNTAIN_AMP,
        max_height: FROZEN_RIVER_MAX_HEIGHT,
        river_carve: 10,
      }
    Ocean =>
      BiomeParams::{
        base_offset: OCEAN_BASE_OFFSET,
        mountain_amp: OCEAN_MOUNTAIN_AMP,
        max_height: OCEAN_MAX_HEIGHT,
        river_carve: 0,
      }
    DeepOcean =>
      BiomeParams::{
        base_offset: DEEP_OCEAN_BASE_OFFSET,
        mountain_amp: DEEP_OCEAN_MOUNTAIN_AMP,
        max_height: DEEP_OCEAN_MAX_HEIGHT,
        river_carve: 0,
      }
  }
}

///|
pub fn name(biome : Biome) -> String {
  match biome {
    Plains => "Plains"
    Forest => "Forest"
    Mountains => "Mountains"
    WindsweptHills => "Windswept Hills"
    Desert => "Desert"
    DesertLakes => "Desert Lakes"
    Beach => "Beach"
    River => "River"
    FrozenRiver => "Frozen River"
    Ocean => "Ocean"
    DeepOcean => "Deep Ocean"
  }
}
