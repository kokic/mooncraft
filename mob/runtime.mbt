///|
let pending_render_configs : Array[@render.GltfEntityConfig] = []

///|
fn flush_pending_render_configs(renderer : @render.GltfRenderer) -> Unit {
  for config in pending_render_configs {
    renderer.add_entity(config)
  }
  pending_render_configs.clear()
}

///|
fn sync_entity_snapshots(renderer : @render.GltfRenderer) -> Unit {
  for snapshot in entity_runtime.snapshots() {
    ignore(
      @render.gltf_set_position(
        renderer,
        snapshot.id,
        snapshot.position.x,
        snapshot.position.y + snapshot.render_y_offset,
        snapshot.position.z,
      ),
    )
    ignore(@render.gltf_set_yaw(renderer, snapshot.id, snapshot.yaw))
  }
}

///|
fn apply_entity_events(
  renderer : @render.GltfRenderer,
  events : Array[@entity.EntityEvent],
) -> Unit {
  for event in events {
    match event {
      MovementStarted(entity_id) => set_mob_animation(renderer, entity_id, true)
      MovementCompleted(entity_id) =>
        set_mob_animation(renderer, entity_id, false)
      MovementCancelled(entity_id) =>
        set_mob_animation(renderer, entity_id, false)
      WaypointReached(_, _) => ()
    }
  }
}

///|
fn set_mob_animation(
  renderer : @render.GltfRenderer,
  entity_id : String,
  moving : Bool,
) -> Unit {
  match entity_runtime.kind(entity_id) {
    Some(Mob(kind)) => {
      let spec = mob_spec(kind)
      let animation = if moving {
        spec.walk_animation
      } else {
        spec.idle_animation
      }
      ignore(@render.gltf_set_animation(renderer, entity_id, animation))
    }
    _ => ()
  }
}

///|
pub fn tick_entity_runtime(
  renderer : @render.GltfRenderer,
  delta : Double,
) -> Unit {
  flush_pending_render_configs(renderer)
  let events = tick_ai()
  events.append(entity_runtime.tick(delta))
  apply_entity_events(renderer, events)
  sync_entity_snapshots(renderer)
}
