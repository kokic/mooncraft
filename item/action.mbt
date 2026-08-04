///|
pub enum BlockSelector {
  Exact(@schema.UniqueID)
  AnyOf(Array[@schema.UniqueID])
}

///|
pub fn BlockSelector::matches(
  selector : BlockSelector,
  name : @schema.UniqueID,
) -> Bool {
  match selector {
    Exact(expected) => name == expected
    AnyOf(names) => {
      for expected in names {
        guard name != expected else { return true }
      }
      false
    }
  }
}

///|
test "block_selector_matches" {
  assert_true(BlockSelector::Exact("water").matches("water"))
  assert_false(BlockSelector::Exact("water").matches(@schema.AIR_NAME))
  assert_true(
    BlockSelector::AnyOf(["grass", "pre-classic.grass"]).matches("grass"),
  )
  assert_true(
    BlockSelector::AnyOf(["grass", "pre-classic.grass"]).matches(
      "pre-classic.grass",
    ),
  )
  assert_false(
    BlockSelector::AnyOf(["grass", "pre-classic.grass"]).matches("stone"),
  )
}

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
    expected~ : BlockSelector,
    neo~ : BlockSelector,
    require_above_air~ : Bool
  )
  PlaceBlock(
    target_wx~ : Int,
    target_wy~ : Int,
    target_wz~ : Int,
    place_wx~ : Int,
    place_wy~ : Int,
    place_wz~ : Int,
    name~ : @schema.UniqueID,
    require_air~ : Bool,
    click~ : (Float, Float, Float)
  )
  Batch(Array[UseOnAction])
}

///|
pub enum UseAction {
  None
  BreakBlock(wx~ : Int, wy~ : Int, wz~ : Int)
  Batch(Array[UseAction])
}
