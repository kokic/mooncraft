///|
pub type Water

///|
/// Default water tint (rgb) and alpha.
/// 
/// Also see: https://zh.minecraft.wiki/w/%E6%B0%B4?variant=zh-cn (Color)
pub let default_water_tint : @util.Rgba = @util.rgba("#3f76e4")

///|
pub let swamp_water_tint : @util.Rgba = @util.rgba("#4c6559")

///|
pub let lukewarm_ocean_water_tint : @util.Rgba = @util.rgba("#45adf2")

///|
pub let warm_ocean_water_tint : @util.Rgba = @util.rgba("#43d5ee")

///|
pub let cold_ocean_water_tint : @util.Rgba = @util.rgba("#3d57d6")

///|
pub let frozen_water_tint : @util.Rgba = @util.rgba("#3938c9")

///|
pub let meadow_water_tint : @util.Rgba = @util.rgba("#0e4ecf")

///|
pub let mangrove_swamp_river_water_tint : @util.Rgba = @util.rgba("#3a7a6a")

///|
pub let cherry_grove_river_water_tint : @util.Rgba = @util.rgba("#5db7ef")

///|
pub let pale_garden_river_water_tint : @util.Rgba = @util.rgba("#76889d")

///|
pub let classic_water_tint : @util.Rgba = @util.rgba("#3341bd")

///|
pub fn Water::tint_for_sample(
  biome : @biome.Biome,
  sample : @biome.BiomeSample,
) -> @util.Rgba {
  match biome {
    @biome.FrozenRiver => frozen_water_tint
    @biome.River =>
      if sample.temperature < -0.22 {
        frozen_water_tint
      } else if sample.humidity > 0.48 && sample.temperature > 0.18 {
        mangrove_swamp_river_water_tint
      } else if sample.humidity > 0.34 {
        swamp_water_tint
      } else {
        default_water_tint
      }
    @biome.Ocean =>
      if sample.temperature > 0.56 {
        warm_ocean_water_tint
      } else if sample.temperature > 0.20 {
        lukewarm_ocean_water_tint
      } else if sample.temperature < -0.24 {
        frozen_water_tint
      } else {
        cold_ocean_water_tint
      }
    @biome.DeepOcean =>
      if sample.temperature < -0.18 {
        frozen_water_tint
      } else {
        cold_ocean_water_tint
      }
    @biome.Desert | @biome.DesertLakes => warm_ocean_water_tint
    @biome.Beach =>
      if sample.temperature > 0.35 {
        lukewarm_ocean_water_tint
      } else {
        default_water_tint
      }
    @biome.Mountains | @biome.WindsweptHills => cold_ocean_water_tint
    @biome.Forest =>
      if sample.humidity > 0.44 {
        swamp_water_tint
      } else {
        default_water_tint
      }
    _ => default_water_tint
  }
}
