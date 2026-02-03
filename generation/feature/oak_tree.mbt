///|
pub fn place_oak_tree(
  set_block : (Int, Int, Int, UInt) -> Unit,
  center_x : Int,
  base_y : Int,
  center_z : Int,
  filler_log? : @block.BlockId = @block.lookup_by_name("oak_log").unwrap().id,
  filler_leaves? : @block.BlockId = @block.lookup_by_name("oak_leaves").unwrap().id,
) -> Unit {
  for ly in 0..<=6 {
    set_block(center_x, base_y + ly, center_z, filler_log)
  }
  for lx in -2..<=2 {
    for lz in -2..<=2 {
      guard !(lx == 0 && lz == 0) else { continue }
      set_block(center_x + lx, base_y + 3, center_z + lz, filler_leaves)
      set_block(center_x + lx, base_y + 4, center_z + lz, filler_leaves)
    }
  }
  for lx in -1..<=1 {
    for lz in -1..<=1 {
      set_block(center_x + lx, base_y + 5, center_z + lz, filler_leaves)
    }
  }
  set_block(center_x - 1, base_y + 6, center_z, filler_leaves)
  set_block(center_x + 1, base_y + 6, center_z, filler_leaves)
  set_block(center_x, base_y + 6, center_z - 1, filler_leaves)
  set_block(center_x, base_y + 6, center_z + 1, filler_leaves)
  set_block(center_x, base_y + 6, center_z, filler_leaves)
}
