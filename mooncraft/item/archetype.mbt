///|
/// Apple nutrition in food points and saturation restored alongside it.
pub let apple_nutrition : Double = 4.0

///|
pub let apple_saturation : Double = 2.4

///|
fn apple_use_action(_stack : ItemStack, _block : Array[Int]) -> UseAction {
  UseAction::Eat(nutrition=apple_nutrition, saturation=apple_saturation)
}

///|
pub fn shovel_use_on(
  _stack : ItemStack,
  x : Int,
  y : Int,
  z : Int,
  face : @shape.FaceName,
  _click : (Float, Float, Float),
) -> UseOnAction {
  if face is @shape.FaceName::PosY {
    UseOnAction::ReplaceBlock(
      wx=x,
      wy=y,
      wz=z,
      expected=BlockSelector::AnyOf(["grass", "pre-classic.grass"]),
      neo=BlockSelector::Exact("grass_path"),
      require_above_air=true,
    )
  } else {
    UseOnAction::None
  }
}
