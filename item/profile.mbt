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
  /// Whether targeting this item should let a raycast stop on liquid blocks.
  include_liquid : Bool
}

///|
/// Whether the named held item's raycast includes liquid blocks. Owned by the
/// item layer so the browser never special-cases item names.
pub fn item_includes_liquid(name : String, category : String) -> Bool {
  match UseTarget::from_wire(name, category) {
    KnownItem(item) => item.profile.include_liquid
    _ => false
  }
}

///|
fn generic_use_action(_stack : ItemStack, block : Array[Int]) -> UseAction {
  UseAction::Batch([
    UseAction::BreakBlock(wx=block[0], wy=block[1], wz=block[2]),
  ])
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
  include_liquid: false,
}

///|
let shovel_profile : ItemProfile = {
  use_action: generic_use_action,
  use_on_action: shovel_use_on,
  include_liquid: false,
}

///|
let bucket_profile : ItemProfile = {
  use_action: generic_use_action,
  use_on_action: bucket_use_on,
  include_liquid: true,
}

///|
let apple_profile : ItemProfile = {
  use_action: apple_use_action,
  use_on_action: generic_use_on_action,
  include_liquid: false,
}
