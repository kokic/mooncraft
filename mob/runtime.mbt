///|
let pending_render_configs : Array[@gltf.GltfEntityConfig] = []

///|
fn flush_pending_render_configs(renderer : @gltf.GltfRenderer) -> Unit {
  for config in pending_render_configs {
    renderer.add_entity(config)
  }
  pending_render_configs.clear()
}

///|
fn sync_entity_snapshots(renderer : @gltf.GltfRenderer) -> Unit {
  for snapshot in entity_runtime.snapshots() {
    ignore(
      @gltf.gltf_set_position(
        renderer,
        snapshot.id,
        snapshot.position.x,
        snapshot.position.y + snapshot.render_y_offset,
        snapshot.position.z,
      ),
    )
    if snapshot.upside_down {
      let rotation = mob_rotation(snapshot.yaw, true)
      ignore(
        @gltf.gltf_set_rotation(
          renderer,
          snapshot.id,
          rotation[0],
          rotation[1],
          rotation[2],
          rotation[3],
        ),
      )
    } else {
      ignore(@gltf.gltf_set_yaw(renderer, snapshot.id, snapshot.yaw))
    }
  }
}

///|
fn mob_rotation(yaw : Double, upside_down : Bool) -> Array[Double] {
  let rotation = [0.0, 0.0, 0.0, 1.0]
  let pitch = if upside_down { @math.PI } else { 0.0 }
  // or, ignore(...)
  let _ = @math3d.quat_from_yaw_pitch(rotation, yaw, pitch)
  rotation
}

///|
fn apply_entity_events(
  renderer : @gltf.GltfRenderer,
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
  renderer : @gltf.GltfRenderer,
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
      ignore(@gltf.gltf_set_animation(renderer, entity_id, animation))
    }
    _ => ()
  }
}

///|
pub fn tick_entity_runtime(
  renderer : @gltf.GltfRenderer,
  delta : Double,
) -> Unit {
  flush_pending_render_configs(renderer)
  let events = tick_ai()
  events.append(entity_runtime.tick(delta))
  apply_entity_events(renderer, events)
  sync_entity_snapshots(renderer)
}
