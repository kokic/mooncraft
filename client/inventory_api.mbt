///|
/// Build browser UI views from the canonical player hotbar definition.
fn collect_hotbar_items() -> Array[@render.UiItemView] {
  @player.hotbar_blocks.map(@render.block_to_ui_item)
}

///|
/// Build inventory UI views from the canonical block and item registries.
fn collect_inventory_items() -> Array[@render.UiItemView] {
  [
    ..@block.blocks
    .filter(block => block.category != @item.None)
    .map(@render.block_to_ui_item),
    ..@item.items
    .filter(item => item.category != @item.None)
    .map(@render.item_to_ui_item),
  ]
}
