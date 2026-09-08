///|
pub(all) enum Category {
  Item
  Block
  None
} derive(Eq)

///|
pub extend Category with Eq::{equal, not_equal}

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
