///|
pub fn use_item(
  _name : String,
  _category : String,
  block : Array[Int],
) -> UseAction {
  if block.length() < 3 {
    UseAction::None
  } else {
    UseAction::Batch([
      UseAction::BreakBlock(wx=block[0], wy=block[1], wz=block[2]),
    ])
  }
}
