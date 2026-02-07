///|
fn can_break_block(long_id : UInt) -> Bool {
  if long_id == @block.AIR_LONG_ID {
    false
  } else {
    match @block.lookup_by_long_id(long_id) {
      Some(block) => block.is_selectable()
      None => false
    }
  }
}

///|
pub fn apply_use_action(
  chunk_map : @ffi.JsValue,
  size : Int,
  action : @item.UseAction,
) -> Array[String] {
  match action {
    @item.UseAction::None => []
    @item.UseAction::Batch(actions) => {
      let out : Array[String] = []
      for sub in actions {
        for key in apply_use_action(chunk_map, size, sub) {
          out.push(key)
        }
      }
      out
    }
    @item.UseAction::BreakBlock(wx~, wy~, wz~) =>
      match get_block_id(chunk_map, size, wx, wy, wz) {
        None => []
        Some(id) =>
          if can_break_block(id) {
            set_block_id(chunk_map, size, wx, wy, wz, @block.AIR_LONG_ID)
          } else {
            []
          }
      }
  }
}
