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
      MovementStarted(entity_id) =>
        ignore(
          @render.gltf_set_animation(
            renderer, entity_id, "animation.zombie.walk",
          ),
        )
      MovementCompleted(entity_id) =>
        ignore(@render.gltf_set_animation(renderer, entity_id, "none"))
      MovementCancelled(entity_id) =>
        ignore(@render.gltf_set_animation(renderer, entity_id, "none"))
      WaypointReached(_, _) => ()
    }
  }
}

///|
pub fn tick_entity_runtime(
  renderer : @render.GltfRenderer,
  delta : Double,
) -> Unit {
  let events = tick_ai()
  events.append(entity_runtime.tick(delta))
  apply_entity_events(renderer, events)
  sync_entity_snapshots(renderer)
}
