///|
pub fn PlayerRuntime::inventory_snapshot(
  self : PlayerRuntime,
) -> PlayerInventorySnapshot {
  self.inventory.snapshot()
}

///|
pub fn PlayerRuntime::restore_inventory(
  self : PlayerRuntime,
  snapshot : PlayerInventorySnapshot,
) -> PlayerInventorySnapshot {
  self.inventory.restore(snapshot)
}

///|
pub fn PlayerRuntime::set_game_mode(
  self : PlayerRuntime,
  mode : String,
) -> PlayerInventorySnapshot {
  let snapshot = self.inventory.set_game_mode(mode)
  if snapshot.game_mode != "creative" {
    self.flying = false
  }
  snapshot
}

///|
/// Toggle creative flight. Has no effect outside creative mode.
pub fn PlayerRuntime::toggle_flight(self : PlayerRuntime) -> PlayerSnapshot {
  guard self.inventory.snapshot().game_mode == "creative" else {
    return self.snapshot()
  }
  self.flying = !self.flying
  self.velocity_y = 0.0
  self.fall_distance = 0.0
  self.snapshot()
}

///|
pub fn PlayerRuntime::select_hotbar(
  self : PlayerRuntime,
  index : Int,
) -> PlayerInventorySnapshot {
  self.inventory.select_hotbar(index)
}

///|
pub fn PlayerRuntime::set_hotbar_slot(
  self : PlayerRuntime,
  index : Int,
  slot : HotbarSlot?,
) -> PlayerInventorySnapshot {
  self.inventory.set_hotbar_slot(index, slot)
}

///|
pub fn PlayerRuntime::set_inventory_open(
  self : PlayerRuntime,
  open : Bool,
) -> PlayerInventorySnapshot {
  self.inventory.set_inventory_open(open)
}
