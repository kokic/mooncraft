///|
pub enum UseOnAction {
  None
  ReplaceBlock(
    wx~ : Int,
    wy~ : Int,
    wz~ : Int,
    expected_name~ : String?,
    new_name~ : String,
    require_above_air~ : Bool
  )
  PlaceBlock(
    target_wx~ : Int,
    target_wy~ : Int,
    target_wz~ : Int,
    place_wx~ : Int,
    place_wy~ : Int,
    place_wz~ : Int,
    name~ : String,
    require_air~ : Bool
  )
  Batch(actions~ : Array[UseOnAction])
}

///|
pub enum UseAction {
  None
  BreakBlock(wx~ : Int, wy~ : Int, wz~ : Int)
  Batch(actions~ : Array[UseAction])
}
