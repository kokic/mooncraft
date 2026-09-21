///|
/// Owns all CPU-side chunk streaming, lighting, and mesh invalidation state.
pub struct ChunkRuntime {
  priv meshes : SectionMeshes
  priv lighting : ChunkLighting
  priv streaming : ColumnScheduler
  world : @level.World
  chunk_map : @hashmap.HashMap[String, Array[UInt]]
  chunk_size : Int
  chunk_min_y : Int
  chunk_max_y : Int
  mut render_distance : Int
  section_size : Int
  sections_per_axis : Int
  generation_budget : Int
  generation_work_budget : Int
  mesh_budget : Int
  priv mut edits : BlockEdits
}

///|
pub fn ChunkRuntime::new(
  world : @level.World,
  initial_chunk : Array[UInt],
  render_distance? : Int = DEFAULT_CHUNK_RENDER_DISTANCE,
  section_size? : Int = CHUNK_SECTION_SIZE,
  generation_budget? : Int = CHUNK_GENERATION_BUDGET,
  generation_work_budget? : Int = CHUNK_GENERATION_WORK_BUDGET,
  mesh_budget? : Int = CHUNK_MESH_BUDGET,
  spawn_chunk_x? : Int = 0,
  spawn_chunk_z? : Int = 0,
) -> ChunkRuntime {
  let chunk_size = @level.CHUNK_X_SIZE
  let normalized_section_size = if section_size > 0 &&
    chunk_size % section_size == 0 {
    section_size
  } else {
    chunk_size
  }
  let chunk_map : @hashmap.HashMap[String, Array[UInt]] = @hashmap.HashMap([])
  let chunk_min_y = @util.floor_div(world.min_y(), chunk_size)
  let chunk_max_y = @util.floor_div(world.max_y(), chunk_size)
  let loaded_columns : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  let dirty_lights : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  seed_spawn_column(
    world, chunk_map, dirty_lights, loaded_columns, initial_chunk, chunk_min_y, chunk_max_y,
    spawn_chunk_x, spawn_chunk_z,
  )
  let light_cache = @level.LightCache::new(
    chunk_size,
    world.min_y(),
    world.max_y(),
  )
  light_cache.update_column(chunk_map, spawn_chunk_x, spawn_chunk_z)
  let runtime = {
    world,
    chunk_map,
    chunk_size,
    chunk_min_y,
    chunk_max_y,
    render_distance: render_distance.clamp(
      min=MIN_RENDER_DISTANCE,
      max=MAX_RENDER_DISTANCE,
    ),
    section_size: normalized_section_size,
    sections_per_axis: chunk_size / normalized_section_size,
    generation_budget: if generation_budget < 1 {
      1
    } else {
      generation_budget
    },
    generation_work_budget: if generation_work_budget < 1 {
      1
    } else {
      generation_work_budget
    },
    mesh_budget: if mesh_budget < 1 {
      1
    } else {
      mesh_budget
    },
    streaming: ColumnScheduler::new(loaded_columns),
    meshes: SectionMeshes::new(world.min_y(), world.max_y()),
    lighting: ChunkLighting::new(light_cache, dirty_lights, normalized_section_size),
    edits: BlockEdits::new(),
  }
  runtime.mark_column_chunks_dirty(spawn_chunk_x, spawn_chunk_z)
  runtime
}

///|
pub fn ChunkRuntime::render_distance(self : ChunkRuntime) -> Int {
  self.render_distance
}

///|
/// Change the desired column radius and force scheduling to refresh next tick.
pub fn ChunkRuntime::set_render_distance(
  self : ChunkRuntime,
  render_distance : Int,
) -> Unit {
  let normalized = render_distance.clamp(
    min=MIN_RENDER_DISTANCE,
    max=MAX_RENDER_DISTANCE,
  )
  guard normalized != self.render_distance else { () }
  self.render_distance = normalized
  self.streaming.has_desired_center = false
}

///|
pub fn ChunkRuntime::chunk_map(
  self : ChunkRuntime,
) -> @hashmap.HashMap[String, Array[UInt]] {
  self.chunk_map
}
