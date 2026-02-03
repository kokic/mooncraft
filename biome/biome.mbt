///|
pub(all) enum Biome {
  Plains
  Forest
  Mountains
  Desert
  DesertLakes
  Beach
  River
  FrozenRiver
}

///|
/// Controls overall biome size; higher => biomes change more frequently.
pub const BIOME_FREQ : Double = 0.01 // 0.002

///|
/// Controls mountain mask scale; higher => more frequent mountain bands.
pub const MOUNTAIN_MASK_FREQ : Double = 0.008

///|
/// Controls continental drift scale; lower => larger landmass variation.
pub const CONTINENTAL_FREQ : Double = 0.004

///|
/// Controls erosion map scale; higher => faster local erosion changes.
pub const EROSION_FREQ : Double = 0.01

///|
/// Temperature threshold for desert selection; higher => fewer deserts.
const DESERT_TEMP_THRESHOLD : Double = 0.25

///|
/// Humidity threshold for desert selection; higher => fewer deserts.
const DESERT_HUMID_THRESHOLD : Double = -0.05

///|
/// Mountain mask threshold; set > 1.0 to effectively disable mountain biomes.
const MOUNTAIN_MASK_THRESHOLD : Double = 1.5

///|
/// Plains base height offset; higher => plains shift upward.
const PLAINS_BASE_OFFSET : Double = 0.0

///|
/// Mountain base height offset; higher => mountains start higher.
const MOUNTAIN_BASE_OFFSET : Double = 8.0

///|
/// Desert base height offset; higher => deserts start higher.
const DESERT_BASE_OFFSET : Double = 0

///|
/// Plains peak amplitude; higher => more pronounced plains hills.
const PLAINS_MOUNTAIN_AMP : Double = 4.0

///|
/// Mountain peak amplitude; higher => taller mountains.
const MOUNTAIN_MOUNTAIN_AMP : Double = 24.0

///|
/// Desert peak amplitude; higher => bumpier deserts.
const DESERT_MOUNTAIN_AMP : Double = 6.0

///|
/// Plains max surface height; higher => taller plains.
const PLAINS_MAX_HEIGHT : Int = 15

///|
/// Desert max surface height; higher => taller deserts.
const DESERT_MAX_HEIGHT : Int = 15

///|
/// Mountain max surface height; higher => taller mountains.
const MOUNTAIN_MAX_HEIGHT : Int = 32

///|
/// Shared FBM helper; higher octaves add detail but increase roughness.
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
/// Biome classification based on temperature, humidity, and mountain mask.
pub fn biome_at(noise : @util.PerlinNoise, wx : Int, wz : Int) -> Biome {
  let x = wx.to_double()
  let z = wz.to_double()
  let temp = fbm2d(noise, x * BIOME_FREQ, z * BIOME_FREQ, 2, 2.0, 0.5)
  let humid = fbm2d(
    noise,
    (x + 1000.0) * BIOME_FREQ,
    (z - 1000.0) * BIOME_FREQ,
    2,
    2.0,
    0.5,
  )
  if temp > DESERT_TEMP_THRESHOLD && humid < DESERT_HUMID_THRESHOLD {
    Desert
  } else {
    let mountain_mask = fbm2d(
      noise,
      x * MOUNTAIN_MASK_FREQ,
      z * MOUNTAIN_MASK_FREQ,
      2,
      2.0,
      0.5,
    ).abs()
    if mountain_mask > MOUNTAIN_MASK_THRESHOLD {
      Mountains
    } else {
      Plains
    }
  }
}

///|
pub struct BiomeParams {
  base_offset : Double
  mountain_amp : Double
  max_height : Int
}

///|
/// Biome tuning parameters for surface shaping.
pub fn params(biome : Biome) -> BiomeParams {
  match biome {
    Plains =>
      BiomeParams::{
        base_offset: PLAINS_BASE_OFFSET,
        mountain_amp: PLAINS_MOUNTAIN_AMP,
        max_height: PLAINS_MAX_HEIGHT,
      }
    Mountains =>
      BiomeParams::{
        base_offset: MOUNTAIN_BASE_OFFSET,
        mountain_amp: MOUNTAIN_MOUNTAIN_AMP,
        max_height: MOUNTAIN_MAX_HEIGHT,
      }
    Desert =>
      BiomeParams::{
        base_offset: DESERT_BASE_OFFSET,
        mountain_amp: DESERT_MOUNTAIN_AMP,
        max_height: DESERT_MAX_HEIGHT,
      }
    _ => BiomeParams::{ base_offset: 0, mountain_amp: 16, max_height: 16 }
  }
}

///|
pub fn name(biome : Biome) -> String {
  match biome {
    Plains => "Plains"
    Forest => "Forest"
    Mountains => "Mountains"
    Desert => "Desert"
    DesertLakes => "Desert Lakes"
    Beach => "Beach"
    River => "River"
    FrozenRiver => "Frozen River"
  }
}
