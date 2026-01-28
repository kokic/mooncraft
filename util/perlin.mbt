///|
pub struct PerlinNoise {
  base : Noise
  grad_p : Array[Vec3[Double]]
}

///|
pub fn PerlinNoise::new(seed? : UInt64 = @env.now()) -> PerlinNoise {
  let base = Noise::new(seed~)
  let grad_p = PerlinNoise::build_gradients(base.permutations)
  PerlinNoise::{ base, grad_p }
}

///|
pub fn PerlinNoise::gen(
  self : PerlinNoise,
  x : Double,
  y : Double,
  z? : Double,
) -> Double {
  match z {
    None => self.gen2d(x, y)
    Some(z) => self.gen3d(x, y, z)
  }
}

///|
pub fn PerlinNoise::gen2d(self : PerlinNoise, x : Double, y : Double) -> Double {
  let fx = x.floor().to_int()
  let fy = y.floor().to_int()
  let rx = x - fx.to_double()
  let ry = y - fy.to_double()
  let ix = fx & 255
  let iy = fy & 255
  let perm = self.base.permutations
  let grad_p = self.grad_p
  let n00 = Vec3::dot(grad_p[ix + perm[iy]], Vec3::new(rx, ry, 0.0))
  let n01 = Vec3::dot(grad_p[ix + perm[iy + 1]], Vec3::new(rx, ry - 1.0, 0.0))
  let n10 = Vec3::dot(grad_p[ix + perm[iy] + 1], Vec3::new(rx - 1.0, ry, 0.0))
  let n11 = Vec3::dot(
    grad_p[ix + perm[iy + 1] + 1],
    Vec3::new(rx - 1.0, ry - 1.0, 0.0),
  )
  let u = Noise::fade2(rx)
  Noise::lerp(
    Noise::lerp(n00, n10, u),
    Noise::lerp(n01, n11, u),
    Noise::fade2(ry),
  )
}

///|
pub fn PerlinNoise::gen3d(
  self : PerlinNoise,
  x : Double,
  y : Double,
  z : Double,
) -> Double {
  let fx = x.floor().to_int()
  let fy = y.floor().to_int()
  let fz = z.floor().to_int()
  let rx = x - fx.to_double()
  let ry = y - fy.to_double()
  let rz = z - fz.to_double()
  let ix = fx & 255
  let iy = fy & 255
  let iz = fz & 255
  let perm = self.base.permutations
  let grad_p = self.grad_p
  let n000 = Vec3::dot(grad_p[ix + perm[iy + perm[iz]]], Vec3::new(rx, ry, rz))
  let n001 = Vec3::dot(
    grad_p[ix + perm[iy + perm[iz + 1]]],
    Vec3::new(rx, ry, rz - 1.0),
  )
  let n010 = Vec3::dot(
    grad_p[ix + perm[iy + 1 + perm[iz]]],
    Vec3::new(rx, ry - 1.0, rz),
  )
  let n011 = Vec3::dot(
    grad_p[ix + perm[iy + 1 + perm[iz + 1]]],
    Vec3::new(rx, ry - 1.0, rz - 1.0),
  )
  let n100 = Vec3::dot(
    grad_p[ix + 1 + perm[iy + perm[iz]]],
    Vec3::new(rx - 1.0, ry, rz),
  )
  let n101 = Vec3::dot(
    grad_p[ix + 1 + perm[iy + perm[iz + 1]]],
    Vec3::new(rx - 1.0, ry, rz - 1.0),
  )
  let n110 = Vec3::dot(
    grad_p[ix + 1 + perm[iy + 1 + perm[iz]]],
    Vec3::new(rx - 1.0, ry - 1.0, rz),
  )
  let n111 = Vec3::dot(
    grad_p[ix + 1 + perm[iy + 1 + perm[iz + 1]]],
    Vec3::new(rx - 1.0, ry - 1.0, rz - 1.0),
  )
  let u = Noise::fade2(rx)
  let v = Noise::fade2(ry)
  let w = Noise::fade2(rz)
  Noise::lerp(
    Noise::lerp(Noise::lerp(n000, n100, u), Noise::lerp(n001, n101, u), w),
    Noise::lerp(Noise::lerp(n010, n110, u), Noise::lerp(n011, n111, u), w),
    v,
  )
}

///|
fn PerlinNoise::build_gradients(perm : Array[Int]) -> Array[Vec3[Double]] {
  let grad3 : Array[Vec3[Double]] = [
    Vec3::new(1.0, 1.0, 0.0),
    Vec3::new(-1.0, 1.0, 0.0),
    Vec3::new(1.0, -1.0, 0.0),
    Vec3::new(-1.0, -1.0, 0.0),
    Vec3::new(1.0, 0.0, 1.0),
    Vec3::new(-1.0, 0.0, 1.0),
    Vec3::new(1.0, 0.0, -1.0),
    Vec3::new(-1.0, 0.0, -1.0),
    Vec3::new(0.0, 1.0, 1.0),
    Vec3::new(0.0, -1.0, 1.0),
    Vec3::new(0.0, 1.0, -1.0),
    Vec3::new(0.0, -1.0, -1.0),
  ]
  let grad_p = Array::make(perm.length(), Vec3::new(0.0, 0.0, 0.0))
  for i in 0..<perm.length() {
    grad_p[i] = grad3[perm[i] % 12]
  }
  grad_p
}
