///|
/// Linear Congruential Generator
pub struct LCG {
  priv mut seed : UInt64
}

///|
pub fn LCG::new(seed? : UInt64 = @env.now()) -> LCG {
  LCG::{ seed, }
}

///|
pub fn LCG::next(self : LCG, modulus? : UInt64) -> UInt64 {
  self.seed = 48271 * self.seed + 57
  match modulus {
    None => self.seed
    Some(modulus) => self.seed % modulus
  }
}
