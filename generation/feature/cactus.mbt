///|
pub fn place_cactus(
  set_block : (Int, Int, Int, UInt) -> Unit,
  center_x : Int,
  base_y : Int,
  center_z : Int,
  filler_cactus? : @block.BlockId = @block.lookup_by_name("cactus").unwrap().id,
) -> Unit {
  let height = @util.random_time_based().int(limit=4)
  for ly in 1..<=height {
    set_block(center_x, base_y + ly, center_z, filler_cactus)
  }
}
