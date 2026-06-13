///|
/// Linear Congruential Generator
pub struct LCG {
  priv mut seed : Int
}

///|
pub fn LCG::LCG(seed? : UInt64 = @env.now()) -> LCG {
  LCG::{ seed: seed.to_int(), }
}

///|
pub fn LCG::next(self : LCG, modulus? : Int) -> Int {
  self.seed = 48271 * self.seed + 57
  match modulus {
    None => self.seed
    Some(modulus) => self.seed % modulus
  }
}
