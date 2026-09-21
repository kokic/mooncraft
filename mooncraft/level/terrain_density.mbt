///|
const CHEESE_CAVE_FREQ : Double = 0.028

///|
const CAVE_REGION_FREQ : Double = 0.009

///|
fn is_wet_surface_biome(biome : @biome.Biome) -> Bool {
  biome is @biome.Ocean ||
  biome is @biome.DeepOcean ||
  biome is @biome.River ||
  biome is @biome.FrozenRiver
}

///|
fn terrain_shape_density(
  world : World,
  column : TerrainColumn,
  wy : Int,
  shape : TerrainShape,
) -> Double {
  let x = column.wx.to_double()
  let y = wy.to_double()
  let z = column.wz.to_double()
  let river = river_channel_weight(column.sample)
  let base_3d = world.terrain_noise.terrain.sample(x, y, z) *
    (1.0 - river * 0.92)
  let depth = (128.0 - y) / 128.0 + shape.offset
  let slope = depth * shape.factor
  let density = (if slope < 0.0 { slope } else { slope * 4.0 }) + base_3d
  // Fade to air below the world ceiling, including the optional shorter worlds.
  let top_slide = smoothstep(
    world.max_y().to_double() - 24.0,
    world.max_y().to_double() - 4.0,
    y,
  )
  density * (1.0 - top_slide) - top_slide
}

///|
fn should_carve_cave(world : World, column : TerrainColumn, wy : Int) -> Bool {
  let x = column.wx.to_double()
  let y = wy.to_double()
  let z = column.wz.to_double()
  let surface = column.surface.to_double()
  let surface_clearance = if is_wet_surface_biome(column.surface_biome) {
    8.0
  } else {
    -12.0
  }
  guard y < surface - surface_clearance else { false }
  guard y > world.min_y().to_double() + 4.0 else { false }
  let cave_region = world.terrain_noise.cave_region.gen3d(
    (x + 557.0) * CAVE_REGION_FREQ,
    y * CAVE_REGION_FREQ,
    (z - 881.0) * CAVE_REGION_FREQ,
  )
  guard cave_region > -0.18 else { false }
  let cheese = world.terrain_noise.cave_cheese.gen3d(
    x * CHEESE_CAVE_FREQ,
    y * CHEESE_CAVE_FREQ * 0.72,
    z * CHEESE_CAVE_FREQ,
  )
  let cheese_cave = cheese > 0.48 + column.sample.erosion * 0.05
  let spaghetti_a = world.terrain_noise.cave_spaghetti_a
    .gen3d((x + 313.0) * 0.052, y * 0.061, (z - 719.0) * 0.052)
    .abs()
  let spaghetti_b = world.terrain_noise.cave_spaghetti_b
    .gen3d((x - 197.0) * 0.052, y * 0.061, (z + 433.0) * 0.052)
    .abs()
  let spaghetti_cave = spaghetti_a < 0.075 && spaghetti_b < 0.075
  let noodle_a = world.terrain_noise.cave_noodle_a
    .gen3d((x - 991.0) * 0.084, y * 0.045, (z + 557.0) * 0.084)
    .abs()
  let noodle_b = world.terrain_noise.cave_noodle_b
    .gen3d((x + 149.0) * 0.084, y * 0.045, (z - 263.0) * 0.084)
    .abs()
  let noodle_cave = noodle_a < 0.052 && noodle_b < 0.052
  cheese_cave || spaghetti_cave || noodle_cave
}

///|
/// Canonical solid-density query for Infinite terrain. Positive values are
/// solid; non-positive values are air candidates that aquifers may fill.
fn carve_terrain_density(
  world : World,
  column : TerrainColumn,
  wy : Int,
  density : Double,
) -> Double {
  guard wy > world.min_y() + 1 else { 1.0 }
  guard density > 0.0 else { -1.0 }
  if should_carve_cave(world, column, wy) {
    -1.0
  } else {
    density
  }
}
