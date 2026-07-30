///|
const NOISE_DEFAULT_SIZE : Int = 8

///|
const NOISE_MAX_SIZE : Int = 64

///|
const NOISE_DEFAULT_OCTAVES : Int = 4

///|
const NOISE_MAX_OCTAVES : Int = 8

///|
const NOISE_DEFAULT_FREQUENCY : Double = 0.05

///|
const NOISE_MIN_FREQUENCY : Double = 0.01

///|
const NOISE_MAX_FREQUENCY : Double = 1.0

///|
const NOISE_DEFAULT_AMPLITUDE : Double = 8.0

///|
const NOISE_MAX_AMPLITUDE : Double = 128.0

///|
const NOISE_SOIL_DEPTH : Int = 3

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
) -> NoiseTarget? {
  self
  .crosshair_block()
  .map(point => {
    let (x, y, z) = point
    { x, y, z, size, seed, frequency, octaves, amplitude }
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
        let material = if wy >= top - NOISE_SOIL_DEPTH {
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
