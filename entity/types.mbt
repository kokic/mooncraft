///|
pub struct EntityPosition {
  x : Double
  y : Double
  z : Double
} derive(Debug, ToJson, FromJson)

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
  Moonbit
} derive(Debug, ToJson, FromJson)

///|
pub fn MobKind::from_name(name : StringView) -> MobKind? {
  match name {
    "zombie" => Some(Zombie)
    "rabbit" => Some(Rabbit)
    "moonbit" => Some(Moonbit)
    "snowman" => Some(Snowman)
    _ => None
  }
}

///|
#warnings("-unused_constructor")
pub(all) enum ProjectileKind {
  Arrow
  Fireball
} derive(Debug, ToJson, FromJson)

///|
#warnings("-unused_constructor")
pub(all) enum EntityKind {
  Mob(MobKind)
  Projectile(ProjectileKind)
  ItemDrop
} derive(Debug, ToJson, FromJson)

///|
pub struct EntitySpawn {
  id : String
  kind : EntityKind
  position : EntityPosition
  render_y_offset : Double
  move_speed : Double
  turn_speed : Double
  upside_down : Bool
  yaw : Double
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
  upside_down? : Bool = false,
  yaw? : Double = 0.0,
) -> EntitySpawn {
  {
    id,
    kind,
    position: EntityPosition::new(x, y, z),
    render_y_offset,
    move_speed,
    turn_speed,
    upside_down,
    yaw,
  }
}

///|
pub struct EntitySnapshot {
  id : String
  kind : EntityKind
  position : EntityPosition
  yaw : Double
  render_y_offset : Double
  upside_down : Bool
} derive(Debug)

///|
/// Persistent movement state for an entity that was moving when the world was saved.
pub struct EntityMovementSave {
  waypoints : Array[EntityPosition]
  next_index : Int
  started : Bool
} derive(Debug, ToJson, FromJson)

///|
/// Complete persistent state owned by the entity runtime.
pub struct EntitySave {
  id : String
  kind : EntityKind
  position : EntityPosition
  yaw : Double
  render_y_offset : Double
  move_speed : Double
  turn_speed : Double
  upside_down : Bool
  movement : EntityMovementSave?
} derive(Debug, ToJson, FromJson)

///|
pub enum EntityEvent {
  MovementStarted(String)
  WaypointReached(String, Int)
  MovementCompleted(String)
  MovementCancelled(String)
} derive(Debug)
