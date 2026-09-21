///|
/// Build browser UI views from the canonical player hotbar definition.
fn collect_hotbar_items() -> Array[@ui.UiItemView] {
  @player.hotbar_blocks.map(@ui.block_to_ui_item)
}

///|
/// Build inventory UI views from the canonical block and item registries.
fn collect_inventory_items() -> Array[@ui.UiItemView] {
  [
    ..@block.blocks
    .filter(block => block.category != @item.None)
    .map(@ui.block_to_ui_item),

    //
    ..@item.items
    .filter(item => item.category != @item.None)
    .map(@ui.item_to_ui_item),
  ]
}

///|
/// Player input, hotbar, and inventory state.
fn register_player_api(game : GameRuntime) -> Unit {
  @ffi.cast_global_set("mcCollectHotbarItems", collect_hotbar_items)
  @ffi.cast_global_set("mcCollectInventoryItems", collect_inventory_items)
  @ffi.cast_global_set("mcHotbarSlotCount", @player.HOTBAR_SLOT_COUNT)
  @ffi.cast_global_set("mcClampHotbarIndex", @player.clamp_hotbar_index)
  @ffi.cast_global_set("mcPlayerSnapshot", () => { game.player_runtime.snapshot() })
  @ffi.cast_global_set("mcSetPlayerMoveIntent", (input : @player.MoveInput) => {
    game.player_runtime.set_move_intent(input)
  })
  @ffi.cast_global_set("mcAddPlayerLookIntent", (
    yaw : Double,
    pitch : Double,
  ) => {
    game.player_runtime.add_look_intent(yaw, pitch)
  })
  @ffi.cast_global_set("mcPlayerInventorySnapshot", () => {
    game.player_runtime.inventory_snapshot()
  })
  @ffi.cast_global_set("mcSetPlayerGameMode", (mode : String) => {
    game.player_runtime.set_game_mode(mode)
  })
  @ffi.cast_global_set("mcTogglePlayerFlight", () => {
    ignore(game.player_runtime.toggle_flight())
  })
  @ffi.cast_global_set("mcSelectPlayerHotbar", (index : Int) => {
    game.player_runtime.select_hotbar(index)
  })
  @ffi.cast_global_set("mcSetPlayerHotbarSlot", (
    index : Int,
    name : String,
    category : String,
  ) => {
    let slot = {
      guard !name.is_empty() else { None }
      Some(@player.HotbarSlot::new(name, category))
    }
    game.player_runtime.set_hotbar_slot(index, slot)
  })
  @ffi.cast_global_set("mcSetPlayerInventoryOpen", (open : Bool) => {
    game.player_runtime.set_inventory_open(open)
  })
}
