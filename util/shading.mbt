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
