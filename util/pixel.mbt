///|
pub const PIXEL_BLOCK_RATIO : Float = 16

///|
/// pixel size to block size
pub fn p2b(n : Int) -> Float {
  Float::from_int(n) / PIXEL_BLOCK_RATIO
}
