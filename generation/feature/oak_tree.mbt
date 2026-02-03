///|
pub fn place_oak_tree_genus(
  set_block : (Int, Int, Int, UInt) -> Unit,
  center_x : Int,
  base_y : Int,
  center_z : Int,
  filler_log? : @block.Block = @block.lookup_by_name("oak_log").unwrap(),
  filler_leaves? : @block.BlockId = @block.lookup_by_name("oak_leaves").unwrap().id,
) -> Unit {
  let filler_log_id = filler_log.id
  let place_fallen_oak_tree = () => {
    let amount = 4 + @util.random_time_based().int(limit=4) // [4, 8)
    if @util.random_time_based().boolean() {
      for lx in -3..<=(amount - 3) {
        set_block(center_x + lx, base_y, center_z, filler_log.long_id(state=1))
      }
    } else {
      for lz in -3..<=(amount - 3) {
        set_block(center_x, base_y, center_z + lz, filler_log.long_id(state=2))
      }
    }
  }
  let place_oak_tree = () => {
    for ly in 0..<=6 {
      set_block(center_x, base_y + ly, center_z, filler_log_id)
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
  match @util.random_time_based().uint(limit=100) {
    p if p < 50 => place_oak_tree()
    _ => place_fallen_oak_tree()
  }
}
