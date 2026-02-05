///|
pub fn shovel_use_on(
  _stack : ItemStack,
  x : Int,
  y : Int,
  z : Int,
  face : @shape.FaceName,
) -> UseOnAction {
  if face is @shape.FaceName::PosY {
    UseOnAction::ReplaceBlock(
      wx=x,
      wy=y,
      wz=z,
      expected_name=Some("grass"),
      new_name="grass_path",
      require_above_air=true,
    )
  } else {
    UseOnAction::None
  }
}
