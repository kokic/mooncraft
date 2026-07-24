///|
test "player inventory runtime normalizes all intents" {
  let runtime = PlayerInventoryRuntime::new(game_mode="invalid", slots=[
    Some(HotbarSlot::new("stone", "block")),
  ])
  let initial = runtime.snapshot()
  assert_eq(initial.game_mode, "creative")
  assert_eq(initial.hotbar_slots.length(), HOTBAR_SLOT_COUNT)
  ignore(runtime.select_hotbar(99))
  ignore(runtime.set_inventory_open(true))
  let snapshot = runtime.snapshot()
  assert_eq(snapshot.selected_hotbar_index, HOTBAR_SLOT_COUNT - 1)
  assert_true(snapshot.inventory_open)
}
