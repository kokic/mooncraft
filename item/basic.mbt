///|
pub type ItemId = UInt

///|
pub struct Item {
  name : @util.UniqueName
  id : ItemId
  texture : String
  category : Category
  profile : ItemProfile
}

///|
pub struct ItemStack {
  item_id : ItemId
  count : Int
}

///|
pub fn ItemStack::from_item(item : Item, count? : Int = 1) -> ItemStack {
  ItemStack::{ item_id: item.id, count }
}

///|
pub fn Item::use_on(
  item : Item,
  stack : ItemStack,
  x : Int,
  y : Int,
  z : Int,
  face : @shape.FaceName,
  click : (Float, Float, Float),
) -> UseOnAction {
  (item.profile.use_on_action)(stack, x, y, z, face, click)
}

///|
pub fn Item::use_action(
  item : Item,
  stack : ItemStack,
  block : Array[Int],
) -> UseAction {
  (item.profile.use_action)(stack, block)
}

///|
fn Item::create(
  name : @util.UniqueName,
  id? : ItemId = alloc_id(),
  category? : Category = Category::Item,
  profile? : ItemProfile = generic_profile,
  texture : String,
) -> Item {
  Item::{ name, id, texture, category, profile }
}
