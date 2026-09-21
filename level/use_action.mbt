///|
fn can_break_block(internal_id : UInt) -> Bool {
  if internal_id == @schema.AIR_ID {
    false
  } else {
    @block.lookup_by_internal_id(internal_id).map_or(false, block => {
      block.is_selectable()
    })
  }
}

///|
/// Apply world effects in order and return the chunk keys needing remeshing.
/// Player effects are handled by the game runtime.
pub fn apply_use_action(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  action : @item.UseAction,
) -> Array[String] {
  BlockInteraction::new(chunk_map, size).apply_use_action(action)
}

///|
fn BlockInteraction::apply_use_action(
  self : BlockInteraction,
  action : @item.UseAction,
) -> Array[String] {
  match action {
    @item.UseAction::None => []
    @item.UseAction::Batch(actions) => {
      let out : Array[String] = []
      for sub in actions {
        for key in self.apply_use_action(sub) {
          out.push(key)
        }
      }
      out
    }
    @item.UseAction::BreakBlock(wx~, wy~, wz~) => {
      guard self.block_at(wx, wy, wz) is Some(id) else { [] }
      guard can_break_block(id) else { [] }
      self.set_block(wx, wy, wz, @schema.AIR_ID)
    }
    // Eating affects the player, not the world, so it is handled by the client.
    @item.UseAction::Eat(..) => []
  }
}
