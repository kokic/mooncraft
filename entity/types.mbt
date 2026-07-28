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
pub(all) enum MobKind {
  Zombie
  Rabbit
  Snowman
} derive(Debug)

///|
pub fn MobKind::from_name(name : StringView) -> MobKind? {
  match name {
    "zombie" => Some(Zombie)
    "rabbit" => Some(Rabbit)
    "snowman" => Some(Snowman)
    _ => None
  }
}

///|
#warnings("-unused_constructor")
pub(all) enum ProjectileKind {
  Arrow
  Fireball
} derive(Debug)

///|
#warnings("-unused_constructor")
pub(all) enum EntityKind {
  Mob(MobKind)
  Projectile(ProjectileKind)
  ItemDrop
} derive(Debug)

///|
pub struct EntitySpawn {
  id : String
  kind : EntityKind
  position : EntityPosition
  render_y_offset : Double
  move_speed : Double
  turn_speed : Double
} derive(Debug)

///|
pub fn EntitySpawn::new(
  id : String,
  kind : EntityKind,
  x : Double,
  y : Double,
  z : Double,
  render_y_offset : Double,
  move_speed : Double,
  turn_speed : Double,
) -> EntitySpawn {
  {
    id,
    kind,
    position: EntityPosition::new(x, y, z),
    render_y_offset,
    move_speed,
    turn_speed,
  }
}

///|
pub struct EntitySnapshot {
  id : String
  kind : EntityKind
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
