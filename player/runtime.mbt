///|
pub const HOTBAR_SLOT_COUNT : Int = 9

///|
/// The persistent identity of one selected UI item.
pub struct HotbarSlot {
  name : String
  category : String
} derive(Debug, ToJson, FromJson)

///|
pub fn HotbarSlot::new(name : String, category : String) -> HotbarSlot {
  { name, category }
}

///|
/// Serializable player-owned UI state. Browser controls render this snapshot;
/// they do not own hotbar selection or inventory visibility.
pub struct PlayerInventorySnapshot {
  game_mode : String
  selected_hotbar_index : Int
  hotbar_slots : Array[HotbarSlot?]
  inventory_open : Bool
} derive(Debug, ToJson, FromJson)

///|
pub struct PlayerInventoryRuntime {
  mut snapshot : PlayerInventorySnapshot
}

///|
fn normalize_game_mode(mode : String) -> String {
  match mode {
    "creative" | "survival" | "spectator" => mode
    _ => "creative"
  }
}

///|
fn clamp_hotbar_index(index : Int) -> Int {
  if index < 0 {
    0
  } else if index >= HOTBAR_SLOT_COUNT {
    HOTBAR_SLOT_COUNT - 1
  } else {
    index
  }
}

///|
fn normalized_slots(slots : Array[HotbarSlot?]) -> Array[HotbarSlot?] {
  let out : Array[HotbarSlot?] = []
  for index in 0..<HOTBAR_SLOT_COUNT {
    out.push(slots.get(index).unwrap_or(None))
  }
  out
}

///|
pub fn PlayerInventoryRuntime::new(
  game_mode? : String = "creative",
  slots? : Array[HotbarSlot?] = [],
) -> PlayerInventoryRuntime {
  {
    snapshot: {
      game_mode: normalize_game_mode(game_mode),
      selected_hotbar_index: 0,
      hotbar_slots: normalized_slots(slots),
      inventory_open: false,
    },
  }
}

///|
pub fn PlayerInventoryRuntime::snapshot(
  self : PlayerInventoryRuntime,
) -> PlayerInventorySnapshot {
  self.snapshot
}

///|
pub fn PlayerInventoryRuntime::set_game_mode(
  self : PlayerInventoryRuntime,
  game_mode : String,
) -> PlayerInventorySnapshot {
  let snapshot = self.snapshot
  self.snapshot = {
    game_mode: normalize_game_mode(game_mode),
    selected_hotbar_index: snapshot.selected_hotbar_index,
    hotbar_slots: snapshot.hotbar_slots,
    inventory_open: snapshot.inventory_open,
  }
  self.snapshot
}

///|
pub fn PlayerInventoryRuntime::select_hotbar(
  self : PlayerInventoryRuntime,
  index : Int,
) -> PlayerInventorySnapshot {
  let snapshot = self.snapshot
  self.snapshot = {
    game_mode: snapshot.game_mode,
    selected_hotbar_index: clamp_hotbar_index(index),
    hotbar_slots: snapshot.hotbar_slots,
    inventory_open: snapshot.inventory_open,
  }
  self.snapshot
}

///|
pub fn PlayerInventoryRuntime::set_hotbar_slot(
  self : PlayerInventoryRuntime,
  index : Int,
  slot : HotbarSlot?,
) -> PlayerInventorySnapshot {
  self.snapshot.hotbar_slots[clamp_hotbar_index(index)] = slot
  self.snapshot
}

///|
pub fn PlayerInventoryRuntime::set_inventory_open(
  self : PlayerInventoryRuntime,
  open : Bool,
) -> PlayerInventorySnapshot {
  let snapshot = self.snapshot
  self.snapshot = {
    game_mode: snapshot.game_mode,
    selected_hotbar_index: snapshot.selected_hotbar_index,
    hotbar_slots: snapshot.hotbar_slots,
    inventory_open: open,
  }
  self.snapshot
}

///|
pub fn PlayerInventoryRuntime::restore(
  self : PlayerInventoryRuntime,
  snapshot : PlayerInventorySnapshot,
) -> PlayerInventorySnapshot {
  self.snapshot = {
    game_mode: normalize_game_mode(snapshot.game_mode),
    selected_hotbar_index: clamp_hotbar_index(snapshot.selected_hotbar_index),
    hotbar_slots: normalized_slots(snapshot.hotbar_slots),
    inventory_open: snapshot.inventory_open,
  }
  self.snapshot
}
