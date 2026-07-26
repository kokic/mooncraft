///|
priv enum TerrainFluid {
  Air
  Water
  Lava
}

///|
const LAVA_AQUIFER_LEVEL : Int = WORLD_MIN_Y + 10

///|
const AQUIFER_BASE_LEVEL : Int = SEA_LEVEL - 24

///|
fn is_ocean_surface(biome : @biome.Biome) -> Bool {
  biome is @biome.Ocean || biome is @biome.DeepOcean || biome is @biome.Beach
}

///|
fn aquifer_fluid_at(
  world : World,
  column : TerrainColumn,
  wy : Int,
  top_solid_wy : Int,
) -> TerrainFluid {
  if is_ocean_surface(column.surface_biome) &&
    wy > top_solid_wy &&
    wy <= SEA_LEVEL {
    return Water
  }
  guard wy < top_solid_wy - 5 else { Air }
  if wy <= LAVA_AQUIFER_LEVEL {
    let lava_barrier = world.noise.gen3d(
      (column.wx.to_double() + 701.0) * 0.043,
      wy.to_double() * 0.043,
      (column.wz.to_double() - 307.0) * 0.043,
    )
    return if lava_barrier > -0.32 { Lava } else { Air }
  }
  let x = column.wx.to_double()
  let z = column.wz.to_double()
  let level_noise = world.noise.gen2d((x + 887.0) * 0.012, (z - 509.0) * 0.012)
  let water_level = AQUIFER_BASE_LEVEL + (level_noise * 11.0).round().to_int()
  guard wy <= water_level else { Air }
  let barrier = world.noise.gen3d(
    (x - 127.0) * 0.026,
    wy.to_double() * 0.031,
    (z + 953.0) * 0.026,
  )
  if barrier > 0.08 {
    Water
  } else {
    Air
  }
}
