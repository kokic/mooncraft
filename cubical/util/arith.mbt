///|
/// Floor division that matches chunk addressing for negative coordinates.
pub fn floor_div(n : Int, d : Int) -> Int {
  let q = n / d
  let r = n % d
  guard !(r == 0 || (r > 0) == (d > 0)) else { q }
  q - 1
}
