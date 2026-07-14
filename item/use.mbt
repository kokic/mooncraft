///|
pub fn use_item(
  name : String,
  category : String,
  block : Array[Int],
) -> UseAction {
  // STATUS: INCOMPLETE - left click currently means "break selected block" for
  // every item. Durability, tool speed, drops, and non-block actions are absent.
  guard block.length() >= 3 && UseTarget::from_wire(name, category).is_usable() else {
    UseAction::None
  }
  UseAction::Batch([
    UseAction::BreakBlock(wx=block[0], wy=block[1], wz=block[2]),
  ])
}
