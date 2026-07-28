///|
pub struct MobSpawnRequest {
  id : String
  kind : @entity.MobKind
  x : Double
  y : Double
  z : Double
  animation : String
  upside_down : Bool
}

///|
pub fn MobSpawnRequest::new(
  id : String,
  kind : @entity.MobKind,
  x : Double,
  y : Double,
  z : Double,
  animation? : String = "none",
  upside_down? : Bool = false,
) -> MobSpawnRequest {
  { id, kind, x, y, z, animation, upside_down }
}

///|
priv struct MobSpec {
  model_url : String
  texture_url : String
  render_y_offset : Double
  scale : Array[Double]
  move_speed : Double
  turn_speed : Double
  idle_animation : String
  walk_animation : String
}

///|
fn mob_spec(kind : @entity.MobKind) -> MobSpec {
  match kind {
    Zombie => zombie_spec()
    Rabbit => rabbit_spec()
    Snowman => snowman_spec()
  }
}
