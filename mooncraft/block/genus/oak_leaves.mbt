///|
pub type OakLeaves

///|
/// Default tint for oak leaves when no biome tint is provided.
pub let default_tint : Array[Float] = [0.38F, 0.74F, 0.22F]

///|
/// Biome tint lookup table size (expected square).
pub let biome_lut_size : Int = 256

///|
/// Climate-driven foliage palette: dry areas are yellow-green, humid warm
/// areas are greener, and cold areas are less saturated. No external LUT.
pub fn OakLeaves::tint_for_sample(sample : @biome.BiomeSample) -> @util.Rgba {
  let warmth = @util.clamp01((sample.temperature + 1.0) * 0.5)
  let moisture = @util.clamp01((sample.humidity + 1.0) * 0.5)
  let lushness = warmth * moisture
  (
    Float::from_double(0.62 - 0.34 * lushness),
    Float::from_double(0.62 + 0.16 * moisture),
    Float::from_double(0.22 + 0.12 * (1.0 - warmth) - 0.08 * lushness),
    1.0F,
  )
}
