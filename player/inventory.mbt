///|
pub const INVENTORY_GRID_X : Int = 9

///|
pub const INVENTORY_GRID_Y : Int = 6

///|
pub fn collect_inventory_defs() -> Array[UiItem] {
  // println(@block.tnt.name)
  // println(@block.oak_log.name)
  // println(@block.oak_leaves.name)
  // println("collect_inventory_defs: \{@block.blocks.length()}")
  @block.blocks.filter(x => x.category != @item.None).map(block_to_ui_def)
}
