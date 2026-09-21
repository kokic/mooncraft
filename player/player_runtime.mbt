///|
pub struct PlayerRuntime {
  chunk_map : @hashmap.HashMap[String, Array[UInt]]
  chunk_size : Int
  world_min_y : Int
  inventory : PlayerInventoryRuntime
  spawn_position : Array[Double]
  mut position : Array[Double]
  mut yaw : Double
  mut pitch : Double
  speed : Double
  entity_height : Double
  entity_radius : Double
  mut move_intent : MoveInput
  mut yaw_intent : Double
  mut pitch_intent : Double
  mut velocity_y : Double
  mut fall_distance : Double
  mut on_ground : Bool
  mut flying : Bool
  mut vitals : Vitals
}

///|
fn idle_move_input() -> MoveInput {
  MoveInput::new()
}

///|
pub fn PlayerRuntime::new(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
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
    spawn_position: position.copy(),
    position,
    yaw,
    pitch: clamp_pitch(pitch),
    speed,
    entity_height,
    entity_radius,
    move_intent: idle_move_input(),
    yaw_intent: 0.0,
    pitch_intent: 0.0,
    velocity_y: 0.0,
    fall_distance: 0.0,
    on_ground: false,
    flying: false,
    vitals: Vitals::full(),
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
  vitals? : Vitals? = None,
  velocity_y? : Double = 0.0,
) -> PlayerSnapshot {
  if position.length() >= 3 {
    self.position = [position[0], position[1], position[2]]
  }
  self.yaw = yaw
  self.pitch = clamp_pitch(pitch)
  self.clear_input()
  self.velocity_y = velocity_y
  self.fall_distance = 0.0
  self.flying = false
  if vitals is Some(value) {
    self.vitals = value
  }
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
  self.clear_input()
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
  // A dead player stops moving until respawn.
  if self.vitals.dead {
    self.move_intent = idle_move_input()
    self.velocity_y = 0.0
    return self.snapshot()
  }
  let game_mode = self.inventory.snapshot().game_mode
  let motion = move_player(
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
    game_mode,
    self.velocity_y,
    self.fall_distance,
    self.flying,
  )
  self.position = motion.position
  self.velocity_y = motion.velocity_y
  self.on_ground = motion.on_ground
  self.fall_distance = if motion.on_ground { 0.0 } else { motion.fall_distance }
  let input = self.move_intent
  let ctx = collect_vitals_context(
    self.chunk_map,
    self.chunk_size,
    self.position,
    self.entity_height,
    self.entity_radius,
    self.world_min_y,
    game_mode,
    input.forward || input.back || input.left || input.right,
    input.sprint && input.forward,
    motion.jumped,
    motion.on_ground,
    motion.fall_distance,
  )
  self.vitals = self.vitals.tick(ctx, delta)
  self.snapshot()
}
