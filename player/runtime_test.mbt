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

///|
test "player runtime consumes look intent and ticks movement" {
  let inventory = PlayerInventoryRuntime::new(game_mode="spectator")
  let runtime = PlayerRuntime::new(
    @ffi.new_map(),
    16,
    0,
    inventory,
    [0.0, 10.0, 0.0],
    0.0,
    0.0,
    speed=2.0,
  )
  runtime.add_look_intent(0.5, -0.25)
  runtime.set_move_intent(MoveInput::new(forward=true))
  let first = runtime.tick(0.5)
  assert_eq(first.yaw, 0.5)
  assert_eq(first.pitch, -0.25)
  assert_true(first.position[0] > 0.0)
  let second = runtime.tick(0.5)
  assert_eq(second.yaw, first.yaw)
  assert_eq(second.pitch, first.pitch)
  assert_true(second.position[0] > first.position[0])
  assert_eq(runtime.position(), second.position)
}
