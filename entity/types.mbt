///|
pub struct EntityPosition {
  x : Double
  y : Double
  z : Double
} derive(Debug)

///|
pub fn EntityPosition::new(
  x : Double,
  y : Double,
  z : Double,
) -> EntityPosition {
  { x, y, z }
}

///|
pub struct EntitySpawn {
  position : EntityPosition
  render_y_offset : Double
  move_speed : Double
  turn_speed : Double
} derive(Debug)

///|
pub fn EntitySpawn::new(
  position : EntityPosition,
  render_y_offset : Double,
  move_speed : Double,
  turn_speed : Double,
) -> EntitySpawn {
  { position, render_y_offset, move_speed, turn_speed }
}

///|
pub struct EntitySnapshot {
  id : String
  position : EntityPosition
  yaw : Double
  render_y_offset : Double
} derive(Debug)

///|
pub enum EntityEvent {
  MovementStarted(String)
  WaypointReached(String, Int)
  MovementCompleted(String)
  MovementCancelled(String)
} derive(Debug)
