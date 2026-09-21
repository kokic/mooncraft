///|
/// CPU output of one mob update. Rendering consumes this after simulation.
priv struct MobFrame {
  spawns : Array[@gltf.GltfEntityConfig]
  snapshots : Array[@entity.EntitySnapshot]
  animations : Array[(String, String)]
}

///|
fn MobRuntime::advance(self : MobRuntime, delta : Double) -> MobFrame {
  let spawns = self.pending_render_configs.copy()
  self.pending_render_configs.clear()
  let events = self.tick_ai()
  events.append(self.entity_runtime.tick(delta))
  let animations : Array[(String, String)] = []
  for event in events {
    let transition = match event {
      MovementStarted(id) => Some((id, true))
      MovementCompleted(id) | MovementCancelled(id) => Some((id, false))
      WaypointReached(_, _) => None
    }
    guard transition is Some((id, moving)) else { continue }
    guard self.entity_runtime.kind(id) is Some(Mob(kind)) else { continue }
    let spec = mob_spec(kind)
    animations.push((id, if moving { spec.walk_animation } else { spec.idle_animation }))
  }
  { spawns, snapshots: self.entity_runtime.snapshots(), animations, }
}

///|
pub fn MobRuntime::tick(
  self : MobRuntime,
  renderer : @gltf.GltfRenderer,
  delta : Double,
) -> Unit {
  self.advance(delta).apply(renderer)
}
