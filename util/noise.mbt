///|
pub fn Noise::lerp(a : Double, b : Double, t : Double) -> Double {
  (1 - t) * a + t * b
}

///|
/// 3t^2 - 2t^3
pub fn Noise::fade(t : Double) -> Double {
  t * t * (2 * t - 3)
}

///|
/// 6t^5 - 15t^4 + 10t^3
pub fn Noise::fade2(t : Double) -> Double {
  t * t * t * (t * (t * 6 - 15) + 10)
}

///|
pub fn Noise::fast(n : Int) -> Double {
  let n = (n << 13) ^ n
  let n = (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff
  let d = n.to_double()
  1.0 - d / 1073741824.0
}

///|
pub struct Noise {
  seed : UInt64
  permutations : Array[Int]
}

///|
pub fn Noise::new(seed? : UInt64 = @env.now()) -> Noise {
  let random = LCG::new(seed~)
  let permutations = Noise::build_permutations(random)
  Noise::{ seed, permutations }
}

///|
fn Noise::build_permutations(random : LCG) -> Array[Int] {
  let perm = Array::make(512, 0)
  for i in 0..<=255 {
    perm[i] = i
  }
  for i in 0..<=255 {
    let span = (256 - i).to_uint64()
    let j = i + random.next(modulus=span).to_int()
    let t = perm[i]
    let v = perm[j]
    perm[i] = v
    perm[i + 256] = v
    perm[j] = t
  }
  perm
}
