///|
pub fn place_cactus(
  set_block : (Int, Int, Int, UInt) -> Unit,
  center_x : Int,
  base_y : Int,
  center_z : Int,
  filler_cactus? : @block.BlockId = @block.lookup_by_name("cactus").unwrap().id,
  seed? : UInt = 0U,
) -> Unit {
  let height = match feature_noise(seed, center_x, base_y, center_z, 53) {
    p if p < -0.5 => 0
    p if p < 0.0 => 1
    p if p < 0.5 => 2
    _ => 3
  }
  for ly in 1..<=height {
    set_block(center_x, base_y + ly, center_z, filler_cactus)
  }
}
