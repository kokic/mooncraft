///|
/// Clamp a Double value to [0, 1].
pub fn clamp01(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
/// Return the value if positive, else 0.
pub fn max0(value : Double) -> Double {
  if value > 0.0 {
    value
  } else {
    0.0
  }
}
