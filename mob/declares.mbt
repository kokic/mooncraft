///|
pub struct MobSpawnRequest {
  id : String
  kind : @entity.MobKind
  x : Double
  y : Double
  z : Double
  animation : String
  upside_down : Bool
  yaw : Double
  scale : Array[Double]
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
  yaw? : Double = 0.0,
  scale : Array[Double],
) -> MobSpawnRequest {
  { id, kind, x, y, z, animation, upside_down, yaw, scale }
}

///|
pub struct MobSpec {
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
/// Owns all per-world mob runtime state: entities, navigation, pathfinding,
/// and pending render configs. Construct one instance per world.
pub struct MobRuntime {
  priv entity_runtime : @entity.EntityRuntime
  priv navigation_requests : @hashmap.HashMap[String, NavigationRequest]
  priv path_searches : @hashmap.HashMap[String, PathSearch]
  priv pending_render_configs : Array[@gltf.GltfEntityConfig]
}

///|
pub fn MobRuntime::new() -> MobRuntime {
  {
    entity_runtime: @entity.EntityRuntime::new(),
    navigation_requests: @hashmap.HashMap([]),
    path_searches: @hashmap.HashMap([]),
    pending_render_configs: [],
  }
}

///|
pub fn mob_spec(kind : @entity.MobKind) -> MobSpec {
  match kind {
    Zombie => zombie_spec()
    Rabbit => rabbit_spec()
    Snowman => snowman_spec()
  }
}
