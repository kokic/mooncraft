///|
priv struct ChunkLighting {
  dirty_lights : @hashmap.HashMap[String, Bool]
  pending_light_chunks : @hashmap.HashMap[String, Bool]
  mut active_light : (String, @level.WorldLightJob)?
  light_cache : @level.LightCache
  mut light_center_y : Int
  lights : @hashmap.HashMap[String, Bytes]
  fixed_section_light : Bytes
}

///|
pub fn ChunkRuntime::chunk_light(self : ChunkRuntime, key : String) -> Bytes? {
  self.lighting.lights.get(key)
}

///|
/// Sample the current combined sky/block light at a world block coordinate.
/// Unloaded lighting uses the same full-bright fallback as chunk meshes.
pub fn ChunkRuntime::light_at(
  self : ChunkRuntime,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Int {
  guard !@level.USE_FIXED_LIGHT else { 15 }
  let size = self.chunk_size
  let address = @level.BlockAddress::new(size, wx, wy, wz)
  let key = address.chunk_key()
  guard self.lighting.lights.get(key) is Some(light) else { 15 }
  let pad = size + 2
  let (stride, offset) = if light.length() == size * size * size {
    (size, 0)
  } else if light.length() == pad * pad * pad {
    (pad, 1)
  } else {
    return 15
  }
  light[address.index(stride, padding=offset)].to_int()
}

///|
fn ChunkRuntime::refresh_lights(self : ChunkRuntime) -> Array[String] {
  guard !@level.USE_FIXED_LIGHT else {
    self.lighting.dirty_lights.clear()
    return []
  }
  for key in self.lighting.dirty_lights.keys() {
    let (x, y, z) = @level.chunk_xyz_by_chunk_key(key)
    for dx in -1..<=1 {
      for dy in -1..<=1 {
        for dz in -1..<=1 {
          let affected = @level.chunk_key_by_chunk_xyz(x + dx, y + dy, z + dz)
          if self.chunk_map.contains(affected) {
            self.lighting.pending_light_chunks[affected] = true
          }
        }
      }
    }
  }
  self.lighting.dirty_lights.clear()
  let updated : Array[String] = []
  for _ in 0..<self.mesh_budget {
    guard self.lighting.active_light is None else { break }
    let mut nearest : String? = None
    let mut nearest_distance = 0
    for key in self.lighting.pending_light_chunks.keys().to_array() {
      guard self.chunk_map.contains(key) else {
        self.lighting.pending_light_chunks.remove(key)
        continue
      }
      let (x, y, z) = @level.chunk_xyz_by_chunk_key(key)
      if y * self.chunk_size > self.meshes.mesh_max_y ||
        (y + 1) * self.chunk_size <= self.meshes.mesh_min_y {
        self.lighting.pending_light_chunks.remove(key)
        continue
      }
      let distance = (x - self.streaming.desired_center_x).abs() +
        (z - self.streaming.desired_center_z).abs() +
        (y - @util.floor_div(self.lighting.light_center_y, self.chunk_size)).abs()
      if nearest is None || distance < nearest_distance {
        nearest = Some(key)
        nearest_distance = distance
      }
    }
    guard nearest is Some(key) else { return updated }
    self.lighting.pending_light_chunks.remove(key)
    if self.lighting.light_cache.uniform_light(key) is Some(light) {
      if self.lighting.lights.get(key) != Some(light) {
        self.lighting.lights[key] = light
        updated.push(key)
      }
      continue
    }
    self.lighting.active_light = Some((key, self.lighting.light_cache.begin([key])))
  }
  guard self.lighting.active_light is Some((_, job)) else { return updated }
  guard job.advance(LIGHT_WORK_BUDGET) else { return updated }
  for (key, light) in job.results() {
    guard self.chunk_map.contains(key) &&
      !self.lighting.pending_light_chunks.contains(key) else {
      continue
    }
    if self.lighting.lights.get(key) != Some(light) {
      self.lighting.lights[key] = light
      updated.push(key)
    }
  }
  self.lighting.active_light = None
  updated
}

///|
/// New geometry must never be published with fallback or obsolete light.
/// Existing meshes stay visible while their replacement is prepared.
fn ChunkRuntime::light_ready(self : ChunkRuntime, key : String) -> Bool {
  @level.USE_FIXED_LIGHT ||
  (
    self.lighting.lights.contains(key) &&
    !self.lighting.dirty_lights.contains(key) &&
    !self.lighting.pending_light_chunks.contains(key) &&
    !self.lighting.active_light.map_or(false, active => active.0 == key)
  )
}

///|
fn ChunkLighting::new(
  light_cache : @level.LightCache,
  dirty_lights : @hashmap.HashMap[String, Bool],
  section_size : Int,
) -> ChunkLighting {
  {
    dirty_lights,
    pending_light_chunks: @hashmap.HashMap([]),
    active_light: None,
    light_cache,
    light_center_y: 0,
    lights: @hashmap.HashMap([]),
    fixed_section_light: Bytes::make(section_size * section_size * section_size, 15),
  }
}
