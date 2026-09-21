///|
const DETAIL_SCALE : Double = 26.0

///|
const DESERT_SAND_DEPTH_MIN : Int = 4

///|
const DESERT_SAND_DEPTH_MAX : Int = 7

///|
const DESERT_SAND_SCALE : Double = 24.0

///|
pub const DESERT_SANDSTONE_DEPTH : Int = 4

///|
fn smoothstep(edge0 : Double, edge1 : Double, value : Double) -> Double {
  let t = @util.clamp01((value - edge0) / (edge1 - edge0))
  t * t * (3.0 - 2.0 * t)
}

///|
/// River corridors follow the valleys of the same weirdness field as mountains.
/// Smooth banks merge into the continental shelf without a biome height switch.
fn river_valley_weight(sample : @biome.BiomeSample) -> Double {
  river_channel_weight(sample) * smoothstep(-0.22, -0.11, sample.continental)
}

///|
fn river_channel_weight(sample : @biome.BiomeSample) -> Double {
  1.0 - smoothstep(0.04, 0.12, sample.river)
}

///|
fn preliminary_surface_height(shape : TerrainShape, world : World) -> Int {
  world.terrain_wy_at_field_y(128.0 + shape.offset * 128.0)
  .round()
  .to_int()
  .max(world.min_y() + 5)
  .min(world.max_y() - 16)
}

///|
/// Select surface cover only after the continuous terrain shape is known.
/// Height thresholds are derived from the canonical field lines so Finite keeps
/// the same biome layout as Infinite.
fn terrain_surface_biome(
  world : World,
  sample : @biome.BiomeSample,
  height : Int,
) -> @biome.Biome {
  let mountain_line = world.terrain_wy_at_field_y(140.0).round().to_int()
  let windswept_line = world.terrain_wy_at_field_y(95.0).round().to_int()
  let beach_line = world
    .terrain_wy_at_field_y((SEA_LEVEL + 3).to_double())
    .round()
    .to_int()
  let sea = world.sea_level()
  match () {
    _ if sample.continental < -0.455 => @biome.DeepOcean
    _ if sample.continental < -0.19 => @biome.Ocean
    _ if sample.river < 0.045 && height < sea =>
      if sample.temperature < -0.45 {
        @biome.FrozenRiver
      } else {
        @biome.River
      }
    _ if sample.continental < -0.11 && height <= beach_line => @biome.Beach
    _ if height >= mountain_line => @biome.Mountains
    _ if height >= windswept_line && sample.erosion < -0.35 =>
      @biome.WindsweptHills
    _ if sample.temperature > 0.2 && sample.humidity < 0.1 => @biome.Desert
    _ if sample.humidity > 0.0 => @biome.Forest
    _ => @biome.Plains
  }
}

///|
/// Highest generated solid terrain block, excluding trees and other decoration.
/// Infinite uses the same interpolated field as filling, including river ice.
pub fn surface_height(world : World, wx : Int, wz : Int) -> Int {
  match world.kind {
    WorldType::Flat => flat_surface_height()
    WorldType::PreClassic => preclassic_surface_height(world, wx, wz)
    WorldType::Design => design_surface_height()
    WorldType::Infinite | WorldType::Finite => {
      let terrain = terrain_column(world, wx, wz)
      let top = highest_solid_y(world, sample_column_densities(world, terrain))
      if terrain.surface_biome is @biome.FrozenRiver && top < world.sea_level() {
        world.sea_level()
      } else {
        top
      }
    }
  }
}

///|
fn surface_dirt_depth(world : World, wx : Int, wz : Int) -> Int {
  let x = world.terrain_field_x(wx)
  let z = world.terrain_field_z(wz)
  let detail = world.terrain_noise.detail
    .gen2d(x / DETAIL_SCALE, z / DETAIL_SCALE)
    .abs()
  3 + (detail * 2.5).floor().to_int()
}

///|
fn desert_sand_depth(world : World, wx : Int, wz : Int) -> Int {
  let x = world.terrain_field_x(wx)
  let z = world.terrain_field_z(wz)
  let t = world.terrain_noise.detail
    .gen2d(x / DESERT_SAND_SCALE, z / DESERT_SAND_SCALE)
    .abs()
  DESERT_SAND_DEPTH_MIN +
  (t * (DESERT_SAND_DEPTH_MAX - DESERT_SAND_DEPTH_MIN).to_double())
  .floor()
  .to_int()
}
