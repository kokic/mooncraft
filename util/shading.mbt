///|
/// Face-based shade factor for axis-aligned block faces.
pub fn face_shade_scale(nx : Int, ny : Int, nz : Int) -> Float {
  if nz != 0 {
    0.8F
  } else if nx != 0 {
    0.6F
  } else if ny == -1 {
    0.5F
  } else {
    1.0F
  }
}

///|
let light_level_scale_table : Array[Float] = {
  let out : Array[Float] = []
  for i in 0..<16 {
    let exp = Float::from_int(15 - i)
    out.push(@math.powf(0.9F, exp))
  }
  out
}

///|
/// Convert a block light level (0-15) to a scalar multiplier.
pub fn light_level_scale(level : Int) -> Float {
  let idx = if level < 0 {
    0
  } else if level > 15 {
    15
  } else {
    level
  }
  light_level_scale_table[idx]
}
