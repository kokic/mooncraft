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
  original_seed : String
  seed : UInt64
  permutations : Array[UInt]
  random : LCG
}
