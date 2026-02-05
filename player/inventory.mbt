///|
pub const INVENTORY_GRID_X : Int = 12

///|
pub const INVENTORY_GRID_Y : Int = 9

///|
pub fn collect_inventory_items() -> Array[UiItemView] {
  let out : Array[UiItemView] = []
  for block in @block.blocks {
    if block.category != @item.None {
      out.push(block_to_ui_item(block))
    }
  }
  for item in @item.items {
    if item.category != @item.None {
      out.push(item_to_ui_item(item))
    }
  }
  out
}
