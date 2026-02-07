///|
pub type ItemId = UInt

///|
pub enum ItemArchetype {
  Generic
  Tool(kind~ : ToolKind, tier~ : ToolTier)
}

///|
pub enum ToolKind {
  Shovel
  // Pickaxe
  // Axe
  // Hoe
  // Sword
}

///|
pub enum ToolTier {
  // Wood
  // Stone
  Iron
  // Gold
  // Diamond
  // Netherite
}

///|
pub struct Item {
  name : @util.UniqueName
  id : ItemId
  texture : String
  category : Category
  archetype : ItemArchetype
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
fn default_use_on(
  _ : ItemStack,
  _ : Int,
  _ : Int,
  _ : Int,
  _ : @shape.FaceName,
  _ : (Float, Float, Float),
) -> UseOnAction {
  UseOnAction::None
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
  match item.archetype {
    ItemArchetype::Tool(kind=ToolKind::Shovel, ..) =>
      shovel_use_on(stack, x, y, z, face, click)
    _ if item.name == "bucket" =>
      Batch([
        ReplaceBlock(
          wx=x,
          wy=y,
          wz=z,
          expected=name => name == "water",
          neo=name => name == "air",
          require_above_air=false,
        ),
      ])
    _ => default_use_on(stack, x, y, z, face, click)
  }
}

///|
fn Item::create(
  name : @util.UniqueName,
  id? : ItemId = alloc_id(),
  category? : Category = Category::Item,
  archetype? : ItemArchetype = ItemArchetype::Generic,
  texture : String,
) -> Item {
  Item::{ name, id, texture, category, archetype }
}
