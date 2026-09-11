///|
fn animation_keyframe(times : @ffi.Float32Array, time : Float) -> Int {
  let count = times.length()
  guard count > 1 else { 0 }
  let values = times.values()
  guard time > Float::from_double(values[0]) else { 0 }
  let last = count - 1
  guard time < Float::from_double(values[last]) else { last - 1 }
  for low = 0, high = last; low + 1 < high; {
    let middle = (low + high) >> 1
    if Float::from_double(values[middle]) <= time {
      continue middle, high
    } else {
      continue low, middle
    }
  } nobreak {
    low
  }
}

///|
fn sample_animation_channel(
  channel : GltfAnimationChannel,
  time : Float,
  translation : Array[Double],
  rotation : Array[Double],
  scale : Array[Double],
) -> Unit {
  let key = animation_keyframe(channel.input, time)
  let next = if key + 1 < channel.input.length() { key + 1 } else { key }
  let times = channel.input.values()
  let t0 = Float::from_double(times[key])
  let t1 = Float::from_double(times[next])
  let fraction = if channel.interpolation == "STEP" || t1 <= t0 {
    0.0
  } else {
    ((time - t0) / (t1 - t0)).to_double()
  }
  let values = channel.output.values()
  if channel.path == "rotation" {
    let first = key * 4
    let second = next * 4
    ignore(
      @camera.quat_slerp(
        rotation,
        [values[first], values[first + 1], values[first + 2], values[first + 3]],
        [
          values[second],
          values[second + 1],
          values[second + 2],
          values[second + 3],
        ],
        fraction,
      ),
    )
    return
  }
  let destination = if channel.path == "translation" {
    translation
  } else {
    scale
  }
  let first = key * 3
  let second = next * 3
  for component in 0..<3 {
    let start = values[first + component]
    destination[component] = start +
      (values[second + component] - start) * fraction
  }
}

///|
fn GltfInstance::update_node_world(
  self : GltfInstance,
  node_index : Int,
  parent : @ffi.Float32Array?,
) -> Unit {
  let world = self.node_world[node_index]
  match parent {
    Some(parent_world) =>
      ignore(@camera.mat4_mul(world, parent_world, self.node_local[node_index]))
    None => ignore(@camera.mat4_copy(world, self.node_local[node_index]))
  }
  for child in self.asset.nodes[node_index].children {
    guard child >= 0 && child < self.asset.nodes.length() else { continue }
    self.update_node_world(child, Some(world))
  }
}

///|
fn GltfInstance::update(self : GltfInstance, delta_seconds : Double) -> Unit {
  let nodes = self.asset.nodes
  let translations = nodes.map(node => node.translation.copy())
  let rotations = nodes.map(node => node.rotation.copy())
  let scales = nodes.map(node => node.scale.copy())
  if self.animation_index >= 0 &&
    self.asset.animations.get(self.animation_index) is Some(animation) {
    self.animation_time += Float::from_double(delta_seconds) *
      self.animation_speed
    if animation.duration > 0.0F {
      if self.animation_looped {
        self.animation_time = self.animation_time % animation.duration
        if self.animation_time < 0.0F {
          self.animation_time += animation.duration
        }
      } else {
        self.animation_time = self.animation_time.clamp(
          min=0.0F,
          max=animation.duration,
        )
      }
    } else {
      self.animation_time = 0.0F
    }
    for channel in animation.channels {
      guard channel.node >= 0 && channel.node < nodes.length() else { continue }
      guard nodes[channel.node].matrix is None else { continue }
      sample_animation_channel(
        channel,
        self.animation_time,
        translations[channel.node],
        rotations[channel.node],
        scales[channel.node],
      )
    }
  }
  for index, node in nodes {
    match node.matrix {
      Some(matrix) => ignore(@camera.mat4_copy(self.node_local[index], matrix))
      None =>
        ignore(
          @camera.mat4_from_trs(
            self.node_local[index],
            translations[index],
            rotations[index],
            scales[index],
          ),
        )
    }
  }
  for root in self.asset.roots {
    guard root >= 0 && root < nodes.length() else { continue }
    self.update_node_world(root, None)
  }
}
