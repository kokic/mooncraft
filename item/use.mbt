///|
pub fn use_item(
  _name : String,
  _category : String,
  block : Array[Int],
) -> UseAction {
  // STATUS: INCOMPLETE - left click currently means "break selected block" for
  // every item. Durability, tool speed, drops, and non-block actions are absent.
  if block.length() < 3 {
    UseAction::None
  } else {
    UseAction::Batch([
      UseAction::BreakBlock(wx=block[0], wy=block[1], wz=block[2]),
    ])
  }
}
