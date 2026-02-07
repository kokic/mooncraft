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
      expected=name => name == "grass" || name == "pre-classic.grass",
      neo=name => name == "grass_path",
      require_above_air=true,
    )
  } else {
    UseOnAction::None
  }
}
