///|
pub const INVENTORY_GRID_X : Int = 12

///|
pub const INVENTORY_GRID_Y : Int = 9

///|
pub fn collect_inventory_items() -> Array[@render.UiItemView] {
  let out : Array[@render.UiItemView] = []
  for block in @block.blocks {
    if block.category != @item.None {
      out.push(@render.block_to_ui_item(block))
    }
  }
  for item in @item.items {
    if item.category != @item.None {
      out.push(@render.item_to_ui_item(item))
    }
  }
  out
}
