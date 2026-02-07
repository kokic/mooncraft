///|
pub fn place_oak_tree_genus(
  set_block : (Int, Int, Int, UInt) -> Unit,
  center_x : Int,
  base_y : Int,
  center_z : Int,
  filler_log? : @block.Block = @block.lookup_by_name("classic.oak_log").unwrap(),
  filler_leaves? : @block.BlockId = @block.lookup_by_name("oak_leaves").unwrap().id,
) -> Unit {
  let filler_log_id = filler_log.id

  //
  let oak_tree = () => {
    // region of elongation
    let elongation = match @util.random_time_based().uint(limit=100) {
      p if p < 50 => 1
      p if p < 70 => 2
      p if p < 90 => 3
      _ => 4
    }
    for ly in 1..<=elongation {
      set_block(center_x, base_y + ly, center_z, filler_log_id)
    }
    let base_y = base_y + elongation
    for ly in 1..<=6 {
      set_block(center_x, base_y + ly, center_z, filler_log_id)
    }
    for lx in -2..<=2 {
      for lz in -2..<=2 {
        guard !(lx == 0 && lz == 0) else { continue }
        set_block(center_x + lx, base_y + 4, center_z + lz, filler_leaves)
        set_block(center_x + lx, base_y + 5, center_z + lz, filler_leaves)
      }
    }
    for lx in -1..<=1 {
      for lz in -1..<=1 {
        set_block(center_x + lx, base_y + 6, center_z + lz, filler_leaves)
      }
    }
    cross_leaves(set_block, center_x, base_y + 7, center_z, filler_leaves)
  }

  //
  let small_fancy_oak = () => {
    for ly in 1..<=4 {
      set_block(center_x, base_y + ly, center_z, filler_log_id)
    }
    for lx in -2..<=2 {
      for lz in -2..<=2 {
        guard !(lx == 0 && lz == 0) else { continue }
        guard !(lx.abs() == 2 && lz.abs() == 2) else { continue }
        set_block(center_x + lx, base_y + 2, center_z + lz, filler_leaves)
        set_block(center_x + lx, base_y + 3, center_z + lz, filler_leaves)
        set_block(center_x + lx, base_y + 4, center_z + lz, filler_leaves)
      }
    }
    cross_leaves(set_block, center_x, base_y + 5, center_z, filler_leaves)
  }

  //
  let tiny_fancy_oak = () => {
    for ly in 1..<=4 {
      set_block(center_x, base_y + ly, center_z, filler_log_id)
    }
    for lx in -2..<=2 {
      for lz in -2..<=2 {
        guard !(lx == 0 && lz == 0) else { continue }
        guard !(lx.abs() == 2 || lz.abs() == 2) else { continue }
        set_block(center_x + lx, base_y + 2, center_z + lz, filler_leaves)
        set_block(center_x + lx, base_y + 3, center_z + lz, filler_leaves)
        set_block(center_x + lx, base_y + 4, center_z + lz, filler_leaves)
      }
    }
    cross_leaves(set_block, center_x, base_y + 5, center_z, filler_leaves)
  }

  //
  match @util.random_time_based().uint(limit=100) {
    p if p < 30 => oak_tree()
    p if p < 60 => small_fancy_oak()
    _ => tiny_fancy_oak()
  }
}

///|
fn cross_leaves(
  set_block : (Int, Int, Int, UInt) -> Unit,
  center_x : Int,
  y : Int,
  center_z : Int,
  filler_leaves : @block.BlockId,
) -> Unit {
  set_block(center_x - 1, y, center_z, filler_leaves)
  set_block(center_x + 1, y, center_z, filler_leaves)
  set_block(center_x, y, center_z - 1, filler_leaves)
  set_block(center_x, y, center_z + 1, filler_leaves)
  set_block(center_x, y, center_z, filler_leaves)
}

///|
pub fn place_fallen_oak_tree(
  set_block : (Int, Int, Int, UInt) -> Unit,
  center_x : Int,
  base_y : Int,
  center_z : Int,
  filler_log? : @block.Block = @block.lookup_by_name("classic.oak_log").unwrap(),
) -> Unit {
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
