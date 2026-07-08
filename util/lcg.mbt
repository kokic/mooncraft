///|
/// Linear Congruential Generator
pub struct LCG {
  priv mut seed : UInt
}

///|
pub fn LCG::LCG(seed? : UInt = @env.now().to_uint()) -> LCG {
  LCG::{ seed, }
}

///|
pub fn LCG::next(self : LCG, modulus? : UInt) -> UInt {
  self.seed = 48271 * self.seed + 57
  modulus.map(m => self.seed % m).unwrap_or(self.seed)
}
