///|
pub enum UseOnAction {
  None
  ReplaceBlock(
    wx~ : Int,
    wy~ : Int,
    wz~ : Int,
    expected~ : @util.UniqueName?,
    neo~ : @util.UniqueName,
    require_above_air~ : Bool
  )
  PlaceBlock(
    target_wx~ : Int,
    target_wy~ : Int,
    target_wz~ : Int,
    place_wx~ : Int,
    place_wy~ : Int,
    place_wz~ : Int,
    name~ : @util.UniqueName,
    require_air~ : Bool
  )
  Batch(Array[UseOnAction])
}

///|
pub enum UseAction {
  None
  BreakBlock(wx~ : Int, wy~ : Int, wz~ : Int)
  Batch(Array[UseAction])
}
