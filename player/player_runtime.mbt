///|
pub struct PlayerSnapshot {
  position : Array[Double]
  yaw : Double
  pitch : Double
  game_mode : String
  entity_height : Double
  entity_radius : Double
} derive(Debug)

///|
pub struct PlayerRuntime {
  chunk_map : @ffi.JsValue
  chunk_size : Int
  world_min_y : Int
  inventory : PlayerInventoryRuntime
  mut position : Array[Double]
  mut yaw : Double
  mut pitch : Double
  speed : Double
  entity_height : Double
  entity_radius : Double
  mut move_intent : MoveInput
  mut yaw_intent : Double
  mut pitch_intent : Double
}

///|
fn idle_move_input() -> MoveInput {
  MoveInput::new()
}

///|
pub fn PlayerRuntime::new(
  chunk_map : @ffi.JsValue,
  chunk_size : Int,
  world_min_y : Int,
  inventory : PlayerInventoryRuntime,
  position : Array[Double],
  yaw : Double,
  pitch : Double,
  speed? : Double = 8.0,
  entity_height? : Double = 1.8,
  entity_radius? : Double = 0.3,
) -> PlayerRuntime {
  let position = if position.length() >= 3 {
    [position[0], position[1], position[2]]
  } else {
    [0.0, world_min_y.to_double(), 0.0]
  }
  {
    chunk_map,
    chunk_size,
    world_min_y,
    inventory,
    position,
    yaw,
    pitch: clamp_pitch(pitch),
    speed,
    entity_height,
    entity_radius,
    move_intent: idle_move_input(),
    yaw_intent: 0.0,
    pitch_intent: 0.0,
  }
}

///|
fn clamp_pitch(pitch : Double) -> Double {
  if pitch < -1.55 {
    -1.55
  } else if pitch > 1.55 {
    1.55
  } else {
    pitch
  }
}

///|
pub fn PlayerRuntime::snapshot(self : PlayerRuntime) -> PlayerSnapshot {
  {
    position: self.position.copy(),
    yaw: self.yaw,
    pitch: self.pitch,
    game_mode: self.inventory.snapshot().game_mode,
    entity_height: self.entity_height,
    entity_radius: self.entity_radius,
  }
}

///|
pub fn PlayerRuntime::set_move_intent(
  self : PlayerRuntime,
  intent : MoveInput,
) -> Unit {
  self.move_intent = intent
}

///|
pub fn PlayerRuntime::add_look_intent(
  self : PlayerRuntime,
  yaw_delta : Double,
  pitch_delta : Double,
) -> Unit {
  self.yaw_intent = self.yaw_intent + yaw_delta
  self.pitch_intent = self.pitch_intent + pitch_delta
}

///|
pub fn PlayerRuntime::restore(
  self : PlayerRuntime,
  position : Array[Double],
  yaw : Double,
  pitch : Double,
) -> PlayerSnapshot {
  if position.length() >= 3 {
    self.position = [position[0], position[1], position[2]]
  }
  self.yaw = yaw
  self.pitch = clamp_pitch(pitch)
  self.move_intent = idle_move_input()
  self.yaw_intent = 0.0
  self.pitch_intent = 0.0
  self.snapshot()
}

///|
/// Move the player immediately and clear pending movement/look input.
pub fn PlayerRuntime::teleport(
  self : PlayerRuntime,
  x : Double,
  y : Double,
  z : Double,
) -> PlayerSnapshot {
  self.position = [x, y, z]
  self.move_intent = idle_move_input()
  self.yaw_intent = 0.0
  self.pitch_intent = 0.0
  self.snapshot()
}

///|
pub fn PlayerRuntime::tick(
  self : PlayerRuntime,
  delta : Double,
) -> PlayerSnapshot {
  self.yaw = self.yaw + self.yaw_intent
  self.pitch = clamp_pitch(self.pitch + self.pitch_intent)
  self.yaw_intent = 0.0
  self.pitch_intent = 0.0
  self.position = move_player(
    self.chunk_map,
    self.chunk_size,
    self.position,
    self.yaw,
    self.move_intent,
    self.speed,
    delta,
    self.entity_height,
    self.entity_radius,
    self.world_min_y,
    self.inventory.snapshot().game_mode,
  )
  self.snapshot()
}

///|
pub fn PlayerRuntime::position(self : PlayerRuntime) -> Array[Double] {
  self.position.copy()
}

///|
pub fn PlayerRuntime::yaw(self : PlayerRuntime) -> Double {
  self.yaw
}

///|
pub fn PlayerRuntime::pitch(self : PlayerRuntime) -> Double {
  self.pitch
}

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
  self.inventory.set_game_mode(mode)
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
