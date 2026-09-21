///|
fn mob_rotation(yaw : Double, upside_down : Bool) -> Array[Double] {
  let rotation = [0.0, 0.0, 0.0, 1.0]
  let pitch = if upside_down { @math.PI } else { 0.0 }
  ignore(@camera.quat_from_yaw_pitch(rotation, yaw, pitch))
  rotation
}

///|
fn MobFrame::apply(self : MobFrame, renderer : @gltf.GltfRenderer) -> Unit {
  for config in self.spawns {
    renderer.add_entity(config)
  }
  for (id, animation) in self.animations {
    ignore(@gltf.gltf_set_animation(renderer, id, animation))
  }
  for snapshot in self.snapshots {
    ignore(@gltf.gltf_set_position(
      renderer,
      snapshot.id,
      snapshot.position.x,
      snapshot.position.y + snapshot.render_y_offset,
      snapshot.position.z,
    ))
    if snapshot.upside_down {
      let rotation = mob_rotation(snapshot.yaw, true)
      ignore(@gltf.gltf_set_rotation(
        renderer, snapshot.id, rotation[0], rotation[1], rotation[2], rotation[3],
      ))
    } else {
      ignore(@gltf.gltf_set_yaw(renderer, snapshot.id, snapshot.yaw))
    }
  }
}
