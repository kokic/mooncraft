///|
pub fn use_item(
  name : String,
  category : String,
  block : Array[Int],
) -> UseAction {
  guard block.length() >= 3 else { UseAction::None }
  // STATUS: INCOMPLETE - durability, tool speed, drops, and non-block actions
  // are absent.  Only KnownItem items can override the default break action via
  // their profile; KnownBlock and Empty (empty hand) always break.
  match UseTarget::from_wire(name, category) {
    KnownItem(item) => item.use_action(ItemStack::from_item(item), block)
    KnownBlock(_) | Empty =>
      UseAction::Batch([
        UseAction::BreakBlock(wx=block[0], wy=block[1], wz=block[2]),
      ])
    Unknown => UseAction::None
  }
}
