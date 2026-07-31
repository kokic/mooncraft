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
  position : @schema.BlockPos
  size : Int
  seed : UInt
  frequency : Double
  octaves : Int
  amplitude : Double
  soil_depth : Int
}

///|
fn NoiseTarget::center_x(target : NoiseTarget) -> Int {
  target.position.x + target.size / 2
}

///|
fn NoiseTarget::center_z(target : NoiseTarget) -> Int {
  target.position.z + target.size / 2
}

///|
fn noise_deltas(target : NoiseTarget) -> Array[@level.BlockDelta] {
  let deltas : Array[@level.BlockDelta] = []
  let noise = @util.PerlinNoise::new(seed=target.seed)
  for dx in 0..<target.size {
    for dz in 0..<target.size {
      let wx = target.position.x + dx
      let wz = target.position.z + dz
      let fbm_val = @biome.fbm2d(
        noise,
        wx.to_double() * target.frequency,
        wz.to_double() * target.frequency,
        target.octaves,
        2.0,
        0.5,
      )
      let height_offset = (fbm_val * target.amplitude).to_int()
      let top = target.position.y.max(target.position.y + height_offset)
      let bottom = target.position.y.min(target.position.y + height_offset)
      for wy in bottom..<top {
        let material = if wy == top - 1 {
          "grass"
        } else if wy >= top - target.soil_depth {
          "dirt"
        } else {
          "stone"
        }
        deltas.push(@level.BlockDelta::new(wx, wy, wz, material))
      }
    }
  }
  deltas
}
