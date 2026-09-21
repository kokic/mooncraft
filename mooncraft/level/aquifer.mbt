///|
/// Fluid kind produced by the aquifer: nothing, water, or deep lava.
priv enum TerrainFluid {
  Air
  Water
  Lava
}

///|
/// Canonical field depth below sea level where aquifer water stops.
const AQUIFER_FIELD_BASE_DEPTH : Double = 24.0

///|
fn aquifer_fluid_at(
  world : World,
  column : TerrainColumn,
  wy : Int,
  top_solid_wy : Int,
) -> TerrainFluid {
  if wy > top_solid_wy && wy <= world.sea_level() {
    return Water
  }
  guard wy < top_solid_wy - 5 else { Air }
  if wy <= world.min_y() + 10 {
    let lava_barrier = world.terrain_noise.aquifer_lava.gen3d(
      (world.terrain_field_x(column.wx) + 701.0) * 0.043,
      world.terrain_field_y(wy) * 0.043,
      (world.terrain_field_z(column.wz) - 307.0) * 0.043,
    )
    return if lava_barrier > -0.32 { Lava } else { Air }
  }
  let x = world.terrain_field_x(column.wx)
  let z = world.terrain_field_z(column.wz)
  let level_noise = world.terrain_noise.aquifer_level.gen2d(
    (x + 887.0) * 0.012,
    (z - 509.0) * 0.012,
  )
  let base_level = world.terrain_wy_at_field_y(
    SEA_LEVEL.to_double() - AQUIFER_FIELD_BASE_DEPTH,
  )
  let level_amplitude = 11.0 / world.terrain_field_scale()
  let water_level = (base_level + (level_noise * level_amplitude).round())
    .to_int()
  guard wy <= water_level else { Air }
  let barrier = world.terrain_noise.aquifer_barrier.gen3d(
    (x - 127.0) * 0.026,
    world.terrain_field_y(wy) * 0.031,
    (z + 953.0) * 0.026,
  )
  if barrier > 0.08 {
    Water
  } else {
    Air
  }
}
