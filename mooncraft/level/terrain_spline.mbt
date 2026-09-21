///|
priv enum TerrainAxis {
  Continents
  Erosion
  Ridges
  Weirdness
}

///|
priv enum TerrainSpline {
  Constant(Double)
  Curve(TerrainAxis, Array[(Double, TerrainSpline, Double)])
}

///|
fn TerrainSpline::sample(
  self : TerrainSpline,
  climate : @biome.BiomeSample,
) -> Double {
  match self {
    Constant(value) => value
    Curve(axis, points) => sample_terrain_curve(axis, points, climate)
  }
}

///|
fn sample_terrain_curve(
  axis : TerrainAxis,
  points : Array[(Double, TerrainSpline, Double)],
  climate : @biome.BiomeSample,
) -> Double {
  let coordinate = match axis {
    Continents => climate.continental
    Erosion => climate.erosion
    Ridges => climate.ridge
    Weirdness => climate.weirdness
  }
  let first = points[0]
  guard coordinate >= first.0 else {
    first.1.sample(climate) + first.2 * (coordinate - first.0)
  }
  for index in 1..<points.length() {
    let upper = points[index]
    guard coordinate < upper.0 else { continue }
    let lower = points[index - 1]
    let span = upper.0 - lower.0
    let t = (coordinate - lower.0) / span
    let a = lower.1.sample(climate)
    let b = upper.1.sample(climate)
    let delta = b - a
    let left_tangent = lower.2 * span - delta
    let right_tangent = -upper.2 * span + delta
    return a +
      delta * t +
      t * (1.0 - t) * (left_tangent + (right_tangent - left_tangent) * t)
  }
  let last = points[points.length() - 1]
  last.1.sample(climate) + last.2 * (coordinate - last.0)
}

///|
priv struct TerrainShape {
  offset : Double
  factor : Double
  jaggedness : Double
}

///|
fn TerrainShape::from_climate(sample : @biome.BiomeSample) -> TerrainShape {
  let offset = terrain_offset_spline.sample(sample) - 0.50375
  let river_bed_offset = (SEA_LEVEL.to_double() - 6.0 - 128.0) / 128.0
  let river = river_valley_weight(sample)
  {
    offset: offset + (river_bed_offset.min(offset) - offset) * river,
    factor: terrain_factor_spline.sample(sample),
    jaggedness: terrain_jaggedness_spline.sample(sample),
  }
}

///|
/// Cache the height-independent jaggedness term once for the whole column.
fn TerrainShape::at_column(
  world : World,
  column : TerrainColumn,
) -> TerrainShape {
  let shape = TerrainShape::from_climate(column.sample)
  guard shape.jaggedness != 0.0 else { shape }
  let noise = world.terrain_noise.jagged.sample(
    column.wx.to_double(),
    column.wz.to_double(),
  )
  let jagged = if noise < 0.0 { noise * 0.5 } else { noise }
  {
    ..shape,
    offset: shape.offset +
    jagged * shape.jaggedness * (1.0 - river_channel_weight(column.sample)),
  }
}
