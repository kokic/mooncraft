///|
pub type ItemId = UInt

///|
let item_id_table : @schema.InternalIDCounter = @schema.InternalIDCounter::new()

///|
fn alloc_item_id() -> @schema.InternalID {
  item_id_table.allocate()
}

///|
pub struct Item {
  name : @schema.UniqueID
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
  name : @schema.UniqueID,
  category? : Category = Category::Item,
  profile? : ItemProfile = generic_profile,
  texture : String,
) -> Item {
  Item::{ name, id: alloc_item_id(), texture, category, profile }
}
