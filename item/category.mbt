///|
pub(all) enum Category {
  Item
  Block
  None
} derive(Eq)

///|
pub fn Category::tag(category : Category) -> String {
  match category {
    Item => "item"
    Block => "block"
    None => "none"
  }
}

///|
pub fn Category::from_tag(tag : String) -> Category? {
  match tag {
    "item" => Some(Item)
    "block" => Some(Block)
    "none" => Some(None)
    _ => None
  }
}

///|
test "category_wire_tags" {
  assert_eq(Category::Item.tag(), "item")
  assert_eq(Category::Block.tag(), "block")
  assert_eq(Category::None.tag(), "none")
  assert_true(Category::from_tag("item") is Some(Item))
  assert_true(Category::from_tag("block") is Some(Block))
  assert_true(Category::from_tag("none") is Some(None))
  assert_true(Category::from_tag("missing") is None)
}
