///|
fn bucket_use_on(
  _stack : ItemStack,
  x : Int,
  y : Int,
  z : Int,
  _face : @shape.FaceName,
  _click : (Float, Float, Float),
) -> UseOnAction {
  Batch([
    ReplaceBlock(
      wx=x,
      wy=y,
      wz=z,
      expected=BlockSelector::Exact("water"),
      neo=BlockSelector::Exact("air"),
      require_above_air=false,
    ),
  ])
}
