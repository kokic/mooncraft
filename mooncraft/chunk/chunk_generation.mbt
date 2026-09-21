///|
/// Pre-generate the chunk column at the spawn point so surface selection and
/// the first frame have complete data. The center chunk at y=0 uses the
/// caller-provided `initial_chunk`.
fn seed_spawn_column(
  world : @level.World,
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  dirty_lights : @hashmap.HashMap[String, Bool],
  loaded_columns : @hashmap.HashMap[String, Bool],
  initial_chunk : Array[UInt],
  chunk_min_y : Int,
  chunk_max_y : Int,
  spawn_chunk_x : Int,
  spawn_chunk_z : Int,
) -> Unit {
  let initial_column : Array[@level.Chunk] = if world.world_type()
    is @level.WorldType::Infinite {
    world.generate_chunk_column(spawn_chunk_x, spawn_chunk_z)
  } else {
    []
  }
  for cy in chunk_min_y..<=chunk_max_y {
    let key = @level.chunk_key_by_chunk_xyz(spawn_chunk_x, cy, spawn_chunk_z)
    let data = if spawn_chunk_x == 0 && cy == 0 && spawn_chunk_z == 0 {
      initial_chunk
    } else if world.world_type() is @level.WorldType::Infinite {
      initial_column[cy - chunk_min_y].tile_map
    } else {
      world.generate_chunk(spawn_chunk_x, cy, spawn_chunk_z).tile_map
    }
    chunk_map[key] = data
    dirty_lights[key] = true
  }
  loaded_columns[@level.chunk_column_key_by_chunk_xz(
    spawn_chunk_x, spawn_chunk_z,
  )] = true
}

///|
fn ChunkRuntime::publish_generated_column(
  self : ChunkRuntime,
  key : String,
  chunks : Array[@level.Chunk],
) -> Array[String] {
  let generated : Array[String] = []
  let (x, z) = @level.chunk_xz_by_chunk_column_key(key)
  for chunk in chunks {
    let chunk_key = chunk.chunk_key()
    let data = chunk.tile_map
    self.edits.apply(self.chunk_size, chunk_key, data)
    self.chunk_map[chunk_key] = data
    self.mark_chunk_sections_dirty(chunk_key)
    self.lighting.dirty_lights[chunk_key] = true
    generated.push(chunk_key)
  }
  self.streaming.loaded_columns[key] = true
  self.lighting.light_cache.update_column(self.chunk_map, x, z)
  self.mark_loaded_neighbor_boundaries_dirty(x, z)
  generated
}

///|
fn ChunkRuntime::generate_queued_infinite(self : ChunkRuntime) -> Array[String] {
  match self.streaming.active_infinite_column {
    Some(generation) =>
      if !self.streaming.desired_columns.contains(generation.column_key()) {
        self.streaming.active_infinite_column = None
      }
    None => ()
  }
  if self.streaming.active_infinite_column is None {
    guard self.streaming.take_queued_column() is Some(key) else { return [] }
    let (x, z) = @level.chunk_xz_by_chunk_column_key(key)
    self.streaming.active_infinite_column = Some(
      self.world.begin_infinite_chunk_column_generation(x, z),
    )
  }
  guard self.streaming.active_infinite_column is Some(generation) else { return [] }
  guard generation.advance(self.generation_work_budget) else { return [] }
  let key = generation.column_key()
  self.streaming.active_infinite_column = None
  guard self.streaming.desired_columns.contains(key) else { return [] }
  guard generation.completed_chunks() is Some(chunks) else { return [] }
  self.publish_generated_column(key, chunks)
}

///|
fn ChunkRuntime::generate_queued_synchronous(
  self : ChunkRuntime,
) -> Array[String] {
  let generated : Array[String] = []
  let mut remaining = self.generation_budget
  while remaining > 0 {
    guard self.streaming.take_queued_column() is Some(key) else { break }
    let (x, z) = @level.chunk_xz_by_chunk_column_key(key)
    for
      chunk_key in self.publish_generated_column(
        key,
        self.world.generate_chunk_column(x, z),
      ) {
      generated.push(chunk_key)
    }
    remaining = remaining - 1
  }
  generated
}

///|
fn ChunkRuntime::generate_queued(self : ChunkRuntime) -> Array[String] {
  if self.world.world_type() is @level.WorldType::Infinite {
    self.generate_queued_infinite()
  } else {
    self.generate_queued_synchronous()
  }
}

///|
fn ChunkRuntime::evict_undesired(self : ChunkRuntime) -> Array[String] {
  let evicted : Array[String] = []
  let center_key = @level.chunk_column_key_by_chunk_xz(
    self.streaming.desired_center_x,
    self.streaming.desired_center_z,
  )
  guard self.streaming.loaded_columns.contains(center_key) else { return evicted }
  for key in self.streaming.loaded_columns.keys().to_array() {
    if self.streaming.desired_columns.contains(key) {
      continue
    }
    let (x, z) = @level.chunk_xz_by_chunk_column_key(key)
    self.mark_loaded_neighbor_boundaries_dirty(x, z)
    self.streaming.loaded_columns.remove(key)
    self.lighting.light_cache.remove_column(x, z)
    for y in self.chunk_min_y..<=self.chunk_max_y {
      let chunk_key = @level.chunk_key_by_chunk_xyz(x, y, z)
      self.remove_chunk_sections(chunk_key)
      self.lighting.dirty_lights.remove(chunk_key)
      self.lighting.lights.remove(chunk_key)
      ignore(self.chunk_map.remove(chunk_key))
      evicted.push(chunk_key)
    }
  }
  evicted
}
