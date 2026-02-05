///|
pub enum UseOnAction {
  None
  ReplaceBlock(
    wx~ : Int,
    wy~ : Int,
    wz~ : Int,
    expected_name~ : String?,
    new_name~ : String,
    require_above_air~ : Bool,
  )
  Batch(actions~ : Array[UseOnAction])
}
