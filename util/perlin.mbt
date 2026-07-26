///|
pub struct PerlinNoise {
  base : Noise
  grad_p : Array[Vec3[Double]]
}

///|
pub fn PerlinNoise::new(seed? : UInt = @env.now().to_uint()) -> PerlinNoise {
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
    Some(z) => self.gen3d(x, y, z)
    None => self.gen2d(x, y)
  }
}

///|
fn gradient_dot(
  gradient : Vec3[Double],
  x : Double,
  y : Double,
  z : Double,
) -> Double {
  gradient.x * x + gradient.y * y + gradient.z * z
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
  let n00 = gradient_dot(grad_p[ix + perm[iy]], rx, ry, 0.0)
  let n01 = gradient_dot(grad_p[ix + perm[iy + 1]], rx, ry - 1.0, 0.0)
  let n10 = gradient_dot(grad_p[ix + perm[iy] + 1], rx - 1.0, ry, 0.0)
  let n11 = gradient_dot(grad_p[ix + perm[iy + 1] + 1], rx - 1.0, ry - 1.0, 0.0)
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
  let n000 = gradient_dot(grad_p[ix + perm[iy + perm[iz]]], rx, ry, rz)
  let n001 = gradient_dot(
    grad_p[ix + perm[iy + perm[iz + 1]]],
    rx,
    ry,
    rz - 1.0,
  )
  let n010 = gradient_dot(
    grad_p[ix + perm[iy + 1 + perm[iz]]],
    rx,
    ry - 1.0,
    rz,
  )
  let n011 = gradient_dot(
    grad_p[ix + perm[iy + 1 + perm[iz + 1]]],
    rx,
    ry - 1.0,
    rz - 1.0,
  )
  let n100 = gradient_dot(
    grad_p[ix + 1 + perm[iy + perm[iz]]],
    rx - 1.0,
    ry,
    rz,
  )
  let n101 = gradient_dot(
    grad_p[ix + 1 + perm[iy + perm[iz + 1]]],
    rx - 1.0,
    ry,
    rz - 1.0,
  )
  let n110 = gradient_dot(
    grad_p[ix + 1 + perm[iy + 1 + perm[iz]]],
    rx - 1.0,
    ry - 1.0,
    rz,
  )
  let n111 = gradient_dot(
    grad_p[ix + 1 + perm[iy + 1 + perm[iz + 1]]],
    rx - 1.0,
    ry - 1.0,
    rz - 1.0,
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
