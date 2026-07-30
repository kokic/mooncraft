///|
/// width and depth of the generated square terrain plane (in blocks)
const NOISE_DEFAULT_SIZE : Int = 16

///|
/// maximum terrain plane size (in blocks)
const NOISE_MAX_SIZE : Int = 64

///|
/// number of stacked noise layers; more octaves produces finer detail and more rugged terrain
const NOISE_DEFAULT_OCTAVES : Int = 4

///|
/// maximum number of octaves
const NOISE_MAX_OCTAVES : Int = 8

///|
/// base spatial frequency of the noise; lower values yield smoother, broader features
const NOISE_DEFAULT_FREQUENCY : Double = 0.05

///|
/// minimum noise frequency
const NOISE_MIN_FREQUENCY : Double = 0.01

///|
/// maximum noise frequency
const NOISE_MAX_FREQUENCY : Double = 1.0

///|
/// vertical height multiplier applied to the noise value; controls maximum terrain elevation
const NOISE_DEFAULT_AMPLITUDE : Double = 32.0

///|
/// maximum noise amplitude
const NOISE_MAX_AMPLITUDE : Double = 128.0

///|
/// number of dirt/soil blocks placed above the stone layer, with grass on the very top
const NOISE_DEFAULT_SOIL_DEPTH : Int = 3

///|
/// minimum soil layer thickness (in blocks)
const NOISE_MIN_SOIL_DEPTH : Int = 1

///|
/// maximum soil layer thickness (in blocks)
const NOISE_MAX_SOIL_DEPTH : Int = 10

///|
priv struct NoiseTarget {
  x : Int
  y : Int
  z : Int
  size : Int
  seed : UInt
  frequency : Double
  octaves : Int
  amplitude : Double
  soil_depth : Int
}

///|
fn NoiseTarget::center_x(self : NoiseTarget) -> Int {
  self.x + self.size / 2
}

///|
fn NoiseTarget::center_z(self : NoiseTarget) -> Int {
  self.z + self.size / 2
}

///|
fn GameRuntime::noise_target(
  self : GameRuntime,
  seed : UInt,
  size : Int,
  frequency : Double,
  octaves : Int,
  amplitude : Double,
  soil_depth : Int,
) -> NoiseTarget? {
  self
  .crosshair_block()
  .map(point => {
    let (x, y, z) = point
    { x, y, z, size, seed, frequency, octaves, amplitude, soil_depth }
  })
}

///|
fn noise_deltas(target : NoiseTarget) -> Array[@level.BlockDelta] {
  let deltas : Array[@level.BlockDelta] = []
  let noise = @util.PerlinNoise::new(seed=target.seed)
  for dx in 0..<target.size {
    for dz in 0..<target.size {
      let wx = target.x + dx
      let wz = target.z + dz
      let fbm_val = @biome.fbm2d(
        noise,
        wx.to_double() * target.frequency,
        wz.to_double() * target.frequency,
        target.octaves,
        2.0,
        0.5,
      )
      let height_offset = (fbm_val * target.amplitude).to_int()
      let bottom = if height_offset >= 0 {
        target.y
      } else {
        target.y + height_offset
      }
      let top = if height_offset >= 0 {
        target.y + height_offset
      } else {
        target.y
      }
      for wy in bottom..<top {
        let material = if wy >= top - target.soil_depth {
          if wy == top - 1 {
            "grass"
          } else {
            "dirt"
          }
        } else {
          "stone"
        }
        deltas.push(@level.BlockDelta::new(wx, wy, wz, material))
      }
    }
  }
  deltas
}
