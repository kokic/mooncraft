///|
pub type Log

///|
pub fn Log::unique_name(base : String, state : UInt) -> String {
  match state {
    1 => "\{base}:x"
    2 => "\{base}:z"
    _ => "\{base}"
  }
}

///|
/// Infer log placement state (axis) from the target block and previous hit.
/// 0 => Y, 1 => X, 2 => Z
pub fn Log::log_state_from_placement(
  block : Array[Int],
  prev : Array[Int],
) -> UInt {
  if block.length() < 3 || prev.length() < 3 {
    0
  } else {
    let dx = block[0] - prev[0]
    let dy = block[1] - prev[1]
    let dz = block[2] - prev[2]
    if dy != 0 {
      0
    } else if dx != 0 {
      1
    } else if dz != 0 {
      2
    } else {
      0
    }
  }
}
