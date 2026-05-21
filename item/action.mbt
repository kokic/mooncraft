///|
pub enum BlockSelector {
  Exact(@util.UniqueName)
  AnyOf(Array[@util.UniqueName])
}

///|
pub fn BlockSelector::matches(
  selector : BlockSelector,
  name : @util.UniqueName,
) -> Bool {
  match selector {
    Exact(expected) => name == expected
    AnyOf(names) => {
      for expected in names {
        if name == expected {
          return true
        }
      }
      false
    }
  }
}

///|
test "block_selector_matches" {
  assert_true(BlockSelector::Exact("water").matches("water"))
  assert_false(BlockSelector::Exact("water").matches("air"))
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
