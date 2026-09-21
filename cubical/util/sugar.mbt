///|
pub fn[T : Mul + Sub] det2(a : T, b : T, c : T, d : T) -> T {
  a * d - b * c
}
