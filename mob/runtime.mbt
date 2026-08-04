///|
fn MobRuntime::flush_pending_render_configs(
  self : MobRuntime,
  renderer : @gltf.GltfRenderer,
) -> Unit {
  for config in self.pending_render_configs {
    renderer.add_entity(config)
  }
  self.pending_render_configs.clear()
}

///|
fn MobRuntime::sync_entity_snapshots(
  self : MobRuntime,
  renderer : @gltf.GltfRenderer,
) -> Unit {
  for snapshot in self.entity_runtime.snapshots() {
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
  let _ = @camera.quat_from_yaw_pitch(rotation, yaw, pitch)
  rotation
}

///|
fn MobRuntime::apply_entity_events(
  self : MobRuntime,
  renderer : @gltf.GltfRenderer,
  events : Array[@entity.EntityEvent],
) -> Unit {
  for event in events {
    match event {
      MovementStarted(entity_id) =>
        self.set_mob_animation(renderer, entity_id, true)
      MovementCompleted(entity_id) =>
        self.set_mob_animation(renderer, entity_id, false)
      MovementCancelled(entity_id) =>
        self.set_mob_animation(renderer, entity_id, false)
      WaypointReached(_, _) => ()
    }
  }
}

///|
fn MobRuntime::set_mob_animation(
  self : MobRuntime,
  renderer : @gltf.GltfRenderer,
  entity_id : String,
  moving : Bool,
) -> Unit {
  match self.entity_runtime.kind(entity_id) {
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
pub fn MobRuntime::tick(
  self : MobRuntime,
  renderer : @gltf.GltfRenderer,
  delta : Double,
) -> Unit {
  self.flush_pending_render_configs(renderer)
  let events = self.tick_ai()
  events.append(self.entity_runtime.tick(delta))
  self.apply_entity_events(renderer, events)
  self.sync_entity_snapshots(renderer)
}
