///|
fn can_break_block(internal_id : UInt) -> Bool {
  if internal_id == @schema.AIR_ID {
    false
  } else {
    @block.lookup_by_internal_id(internal_id)
    .map(block => block.is_selectable())
    .unwrap_or(false)
  }
}

///|
pub fn apply_use_action(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  action : @item.UseAction,
) -> Array[String] {
  // STATUS: COMPLETE - applies the current break-block action contract.
  // STATUS: INCOMPLETE - item durability, harvest rules, drops, and event hooks
  // are intentionally absent from this first interaction layer.
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
            set_block_id(chunk_map, size, wx, wy, wz, @schema.AIR_ID)
          } else {
            []
          }
      }
  }
}
