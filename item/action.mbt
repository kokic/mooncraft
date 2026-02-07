///|
pub type UniqueNamePredicate = (@util.UniqueName) -> Bool

///|
pub enum UseOnAction {
  None
  // ReplaceItem(
  //   expected~ : UniqueNamePredicate,
  //   neo~ : UniqueNamePredicate
  // )
  ReplaceBlock(
    wx~ : Int,
    wy~ : Int,
    wz~ : Int,
    expected~ : UniqueNamePredicate,
    neo~ : UniqueNamePredicate,
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
