///|
priv struct TerrainNoiseOctave {
  noise : @util.PerlinNoise
  offset_x : Double
  offset_y : Double
  offset_z : Double
}

///|
/// Legacy blended terrain noise: two 16-octave limits selected by an 8-octave
/// field. Scales and weights follow Java 1.18.2's default 4x8 noise cells.
/// Permutations use Mooncraft seeds; vertical smear is not emulated.
pub struct TerrainBlendedNoise {
  priv lower : Array[TerrainNoiseOctave]
  priv upper : Array[TerrainNoiseOctave]
  priv selector : Array[TerrainNoiseOctave]
}

///|
fn terrain_noise_octaves(
  seed : UInt,
  salt : UInt,
  count : Int,
) -> Array[TerrainNoiseOctave] {
  let result : Array[TerrainNoiseOctave] = []
  for index in 0..<count {
    let octave_seed = salted_seed(
      seed,
      salt + index.reinterpret_as_uint() * 0x9e3779b9U,
    )
    result.push({
      noise: @util.PerlinNoise::new(seed=octave_seed),
      offset_x: salted_seed(octave_seed, 0x51U).to_double() / 16777216.0,
      offset_y: salted_seed(octave_seed, 0x52U).to_double() / 16777216.0,
      offset_z: salted_seed(octave_seed, 0x53U).to_double() / 16777216.0,
    })
  }
  result
}

///|
fn TerrainBlendedNoise::new(seed : UInt) -> TerrainBlendedNoise {
  {
    lower: terrain_noise_octaves(seed, 0x201U, 16),
    upper: terrain_noise_octaves(seed, 0x202U, 16),
    selector: terrain_noise_octaves(seed, 0x203U, 8),
  }
}

///|
fn sample_terrain_octaves(
  octaves : Array[TerrainNoiseOctave],
  x : Double,
  y : Double,
  z : Double,
  frequency : Double,
  amplitude : Double,
) -> Double {
  for sum = 0.0, index = 0, frequency = frequency, amplitude = amplitude {
    guard index < octaves.length() else { break sum }
    let octave = octaves[index]
    let value = octave.noise.gen3d(
      x * frequency + octave.offset_x,
      y * frequency + octave.offset_y,
      z * frequency + octave.offset_z,
    )
    continue sum + value * amplitude,
      index + 1,
      frequency * 2.0,
      amplitude * 0.5
  }
}

///|
fn TerrainBlendedNoise::sample(
  self : TerrainBlendedNoise,
  x : Double,
  y : Double,
  z : Double,
) -> Double {
  let x = x * 684.412 / 4.0
  let y = y * 684.412 / 8.0
  let z = z * 684.412 / 4.0
  let blend = @util.clamp01(
    0.5 +
    sample_terrain_octaves(
      self.selector,
      x / 80.0,
      y / 160.0,
      z / 80.0,
      1.0 / 128.0,
      6.4,
    ),
  )
  let lower = if blend < 1.0 {
    sample_terrain_octaves(self.lower, x, y, z, 1.0 / 32768.0, 0.5)
  } else {
    0.0
  }
  let upper = if blend > 0.0 {
    sample_terrain_octaves(self.upper, x, y, z, 1.0 / 32768.0, 0.5)
  } else {
    0.0
  }
  lower + (upper - lower) * blend
}
