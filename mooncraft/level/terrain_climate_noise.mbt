///|
priv struct ClimateOctave {
  first : @util.PerlinNoise
  second : @util.PerlinNoise
  offset_x : Double
  offset_y : Double
  offset_z : Double
  frequency : Double
  amplitude : Double
}

///|
/// Two independently seeded octave stacks, using the 1.18.2 normal-noise
/// amplitude normalization. World seeds retain Mooncraft's UInt convention.
pub struct ClimateNoise {
  priv octaves : Array[ClimateOctave]
  priv normalization : Double
}

///|
fn ClimateNoise::new(
  seed : UInt,
  salt : UInt,
  frequency : Double,
  amplitudes : Array[Double],
) -> ClimateNoise {
  let octaves : Array[ClimateOctave] = []
  let count = amplitudes.length()
  let first_weight = (1 << (count - 1)).to_double() /
    ((1 << count) - 1).to_double()
  let (first, last) = for first = count, last = 0, index = 0 {
    guard index < count else { break (first, last) }
    if amplitudes[index] != 0.0 {
      let octave_seed = salted_seed(
        seed,
        salt + index.reinterpret_as_uint() * 0x9e3779b9U,
      )
      octaves.push({
        first: @util.PerlinNoise::new(seed=octave_seed),
        second: @util.PerlinNoise::new(
          seed=salted_seed(octave_seed, 0xa511e9b3U),
        ),
        offset_x: salted_seed(octave_seed, 0x41U).to_double() / 16777216.0,
        offset_y: salted_seed(octave_seed, 0x42U).to_double() / 16777216.0,
        offset_z: salted_seed(octave_seed, 0x43U).to_double() / 16777216.0,
        frequency: frequency * (1 << index).to_double(),
        amplitude: amplitudes[index] * first_weight / (1 << index).to_double(),
      })
      continue first.min(index), index, index + 1
    }
    continue first, last, index + 1
  }
  {
    octaves,
    normalization: 1.0 /
    6.0 /
    (0.1 * (1.0 + 1.0 / (last - first + 1).to_double())),
  }
}

///|
fn ClimateNoise::sample(self : ClimateNoise, x : Double, z : Double) -> Double {
  let sum = for sum = 0.0, index = 0 {
    guard index < self.octaves.length() else { break sum }
    let octave = self.octaves[index]
    let nx = x * octave.frequency
    let nz = z * octave.frequency
    let first = octave.first.gen3d(
      nx + octave.offset_x,
      octave.offset_y,
      nz + octave.offset_z,
    )
    let second = octave.second.gen3d(
      nx * 1.0181268882175227 + octave.offset_z,
      octave.offset_x,
      nz * 1.0181268882175227 + octave.offset_y,
    )
    continue sum + (first + second) * octave.amplitude, index + 1
  }
  sum * self.normalization
}
