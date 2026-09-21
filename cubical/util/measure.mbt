///|
pub const PIXEL_BLOCK_RATIO : Float = 16

///|
/// pixel size to block size
#alias(p2b)
pub fn pixel_to_block_size(n : Int) -> Float {
  Float::from_int(n) / PIXEL_BLOCK_RATIO
}
