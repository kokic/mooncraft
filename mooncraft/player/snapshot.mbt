///|
pub struct PlayerSnapshot {
  position : Array[Double]
  yaw : Double
  pitch : Double
  game_mode : String
  entity_height : Double
  entity_radius : Double
  velocity_y : Double
  on_ground : Bool
  flying : Bool
  health : Double
  hunger : Double
  air : Double
  dead : Bool
} derive(Debug)

///|
pub extend PlayerSnapshot with Debug::{to_repr}

///|
pub fn PlayerRuntime::snapshot(self : PlayerRuntime) -> PlayerSnapshot {
  {
    position: self.position.copy(),
    yaw: self.yaw,
    pitch: self.pitch,
    game_mode: self.inventory.snapshot().game_mode,
    entity_height: self.entity_height,
    entity_radius: self.entity_radius,
    velocity_y: self.velocity_y,
    on_ground: self.on_ground,
    flying: self.flying,
    health: self.vitals.health,
    hunger: self.vitals.hunger,
    air: self.vitals.air,
    dead: self.vitals.dead,
  }
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
pub fn PlayerRuntime::velocity_y(self : PlayerRuntime) -> Double {
  self.velocity_y
}
