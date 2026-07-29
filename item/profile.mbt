///|
pub(all) struct ItemProfile {
  use_action : (ItemStack, Array[Int]) -> UseAction
  use_on_action : (
    ItemStack,
    Int,
    Int,
    Int,
    @shape.FaceName,
    (Float, Float, Float),
  ) -> UseOnAction
}

///|
fn generic_use_action(
  _stack : ItemStack,
  block : Array[Int],
) -> UseAction {
  UseAction::Batch([UseAction::BreakBlock(wx=block[0], wy=block[1], wz=block[2])])
}

///|
fn generic_use_on_action(
  _stack : ItemStack,
  _x : Int,
  _y : Int,
  _z : Int,
  _face : @shape.FaceName,
  _click : (Float, Float, Float),
) -> UseOnAction {
  UseOnAction::None
}

///|
let generic_profile : ItemProfile = {
  use_action: generic_use_action,
  use_on_action: generic_use_on_action,
}

///|
let shovel_profile : ItemProfile = {
  use_action: generic_use_action,
  use_on_action: shovel_use_on,
}

///|
let bucket_profile : ItemProfile = {
  use_action: generic_use_action,
  use_on_action: bucket_use_on,
}
