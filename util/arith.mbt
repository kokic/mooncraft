///|
/// Floor division that matches chunk addressing for negative coordinates.
pub fn floor_div(n : Int, d : Int) -> Int {
  let q = n / d
  let r = n % d
  if r == 0 {
    q
  } else if (r > 0) == (d > 0) {
    q
  } else {
    q - 1
  }
}
