///|
pub fn PlayerRuntime::vitals(self : PlayerRuntime) -> Vitals {
  self.vitals
}

///|
/// Apply a discrete hit and return the resulting snapshot.
pub fn PlayerRuntime::apply_damage(
  self : PlayerRuntime,
  amount : Double,
) -> PlayerSnapshot {
  self.vitals = self.vitals.apply_hit(amount)
  self.snapshot()
}

///|
/// Restore health and return the resulting snapshot.
pub fn PlayerRuntime::heal(
  self : PlayerRuntime,
  amount : Double,
) -> PlayerSnapshot {
  self.vitals = self.vitals.heal(amount)
  self.snapshot()
}

///|
/// Feed the player and return the resulting snapshot.
pub fn PlayerRuntime::eat(
  self : PlayerRuntime,
  nutrition : Double,
  saturation : Double,
) -> PlayerSnapshot {
  self.vitals = self.vitals.eat(nutrition, saturation)
  self.snapshot()
}

///|
/// Kill the player and return the resulting snapshot.
pub fn PlayerRuntime::kill(self : PlayerRuntime) -> PlayerSnapshot {
  self.vitals = self.vitals.kill()
  self.snapshot()
}

///|
/// Return to the spawn point with full health and food.
pub fn PlayerRuntime::respawn(self : PlayerRuntime) -> PlayerSnapshot {
  self.position = self.spawn_position.copy()
  self.velocity_y = 0.0
  self.fall_distance = 0.0
  self.on_ground = false
  self.flying = false
  self.vitals = Vitals::full()
  self.clear_input()
  self.snapshot()
}
