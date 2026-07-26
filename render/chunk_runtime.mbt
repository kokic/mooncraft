///|
pub const CHUNK_RENDER_DISTANCE : Int = 2

///|
pub const CHUNK_SECTION_SIZE : Int = 8

///|
pub const CHUNK_GENERATION_BUDGET : Int = 1

///|
pub const CHUNK_GENERATION_WORK_BUDGET : Int = 8

///|
pub const CHUNK_MESH_BUDGET : Int = 8

///|
/// Owns all CPU-side chunk streaming, lighting, and mesh invalidation state.
/// `chunk_map` is an opaque browser map used only as a zero-copy data bridge.
pub struct ChunkRuntime {
  world : @level.World
  chunk_map : @ffi.JsValue
  chunk_size : Int
  chunk_min_y : Int
  chunk_max_y : Int
  render_distance : Int
  section_size : Int
  sections_per_axis : Int
  generation_budget : Int
  generation_work_budget : Int
  mesh_budget : Int
  loaded_columns : Map[String, Bool]
  mut desired_columns : Map[String, Bool]
  mut desired_center_x : Int
  mut desired_center_z : Int
  mut has_desired_center : Bool
  queued_columns : Map[String, Bool]
  mut column_queue : Array[String]
  mut queue_head : Int
  mut active_infinite_column : @level.InfiniteChunkColumnGeneration?
  dirty_sections : Map[String, ChunkSection]
  rendered_sections : Map[String, ChunkSection]
  mut dirty_lights : Map[String, Bool]
  lights : Map[String, Bytes]
  fixed_section_light : Bytes
  block_deltas : Map[String, @level.BlockDelta]
}

///|
fn section_key(chunk_key : String, x : Int, y : Int, z : Int) -> String {
  "\{chunk_key}|\{x},\{y},\{z}"
}

///|
fn chunk_key_by_world(size : Int, wx : Int, wy : Int, wz : Int) -> String {
  @level.chunk_key_by_chunk_xyz(
    @util.floor_div(wx, size),
    @util.floor_div(wy, size),
    @util.floor_div(wz, size),
  )
}

///|
fn chunk_column_key_by_world(size : Int, wx : Int, wz : Int) -> String {
  @level.chunk_column_key_by_chunk_xz(
    @util.floor_div(wx, size),
    @util.floor_div(wz, size),
  )
}

///|
pub fn ChunkRuntime::new(
  world : @level.World,
  initial_chunk : Array[UInt],
  render_distance? : Int = CHUNK_RENDER_DISTANCE,
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
  let chunk_map = @ffi.new_map()
  let chunk_min_y = @util.floor_div(world.min_y(), chunk_size)
  let chunk_max_y = @util.floor_div(world.max_y(), chunk_size)
  let loaded_columns : Map[String, Bool] = Map([])
  let dirty_lights : Map[String, Bool] = Map([])
  let initial_column : Array[@level.Chunk] = if world.world_type()
    is @level.WorldType::Infinite {
    world.generate_chunk_column(spawn_chunk_x, spawn_chunk_z)
  } else {
    []
  }
  // Spawn surface selection needs a complete column before the first frame.
  for cy in chunk_min_y..<=chunk_max_y {
    let key = @level.chunk_key_by_chunk_xyz(spawn_chunk_x, cy, spawn_chunk_z)
    let data = if spawn_chunk_x == 0 && cy == 0 && spawn_chunk_z == 0 {
      initial_chunk
    } else if world.world_type() is @level.WorldType::Infinite {
      initial_column[cy - chunk_min_y].tile_map
    } else {
      world.generate_chunk(spawn_chunk_x, cy, spawn_chunk_z).tile_map
    }
    @ffi.map_set_value(chunk_map, key, data)
    dirty_lights[key] = true
  }
  loaded_columns[@level.chunk_column_key_by_chunk_xz(
    spawn_chunk_x, spawn_chunk_z,
  )] = true
  let runtime = {
    world,
    chunk_map,
    chunk_size,
    chunk_min_y,
    chunk_max_y,
    render_distance: if render_distance < 0 {
      0
    } else {
      render_distance
    },
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
    loaded_columns,
    desired_columns: {},
    desired_center_x: 0,
    desired_center_z: 0,
    has_desired_center: false,
    queued_columns: {},
    column_queue: [],
    queue_head: 0,
    active_infinite_column: None,
    dirty_sections: {},
    rendered_sections: {},
    dirty_lights,
    lights: {},
    fixed_section_light: Bytes::make(
      normalized_section_size *
      normalized_section_size *
      normalized_section_size,
      15,
    ),
    block_deltas: {},
  }
  runtime.mark_column_chunks_dirty(spawn_chunk_x, spawn_chunk_z)
  runtime
}

///|
pub fn ChunkRuntime::chunk_map(self : ChunkRuntime) -> @ffi.JsValue {
  self.chunk_map
}

///|
pub fn ChunkRuntime::chunk_light(self : ChunkRuntime, key : String) -> Bytes? {
  self.lights.get(key)
}

///|
fn ChunkRuntime::enqueue_column(self : ChunkRuntime, key : String) -> Unit {
  let is_active = match self.active_infinite_column {
    Some(generation) => generation.column_key() == key
    None => false
  }
  guard !self.loaded_columns.contains(key) &&
    !self.queued_columns.contains(key) &&
    !is_active else {
    return
  }
  self.queued_columns[key] = true
  self.column_queue.push(key)
}

///|
fn ChunkRuntime::refresh_desired(
  self : ChunkRuntime,
  center_x : Int,
  center_z : Int,
) -> Unit {
  // Desired chunk keys only change when the player enters another column.
  // Avoid rebuilding the render-distance map and re-enqueuing keys every frame.
  if self.has_desired_center &&
    self.desired_center_x == center_x &&
    self.desired_center_z == center_z {
    return
  }
  self.has_desired_center = true
  self.desired_center_x = center_x
  self.desired_center_z = center_z
  self.desired_columns = {}
  for
    key in collect_render_column_keys(center_x, center_z, self.render_distance) {
    self.desired_columns[key] = true
    self.enqueue_column(key)
  }
}

///|
fn ChunkRuntime::take_queued_column(self : ChunkRuntime) -> String? {
  while self.queue_head < self.column_queue.length() {
    let key = self.column_queue[self.queue_head]
    self.queue_head = self.queue_head + 1
    self.queued_columns.remove(key)
    if self.loaded_columns.contains(key) || !self.desired_columns.contains(key) {
      continue
    }
    return Some(key)
  }
  self.column_queue = []
  self.queue_head = 0
  None
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
    self.apply_block_deltas(chunk_key, data)
    @ffi.map_set_value(self.chunk_map, chunk_key, data)
    self.mark_chunk_sections_dirty(chunk_key)
    self.dirty_lights[chunk_key] = true
    generated.push(chunk_key)
  }
  self.loaded_columns[key] = true
  self.mark_loaded_neighbor_boundaries_dirty(x, z)
  generated
}

///|
fn ChunkRuntime::generate_queued_infinite(self : ChunkRuntime) -> Array[String] {
  match self.active_infinite_column {
    Some(generation) =>
      if !self.desired_columns.contains(generation.column_key()) {
        self.active_infinite_column = None
      }
    None => ()
  }
  if self.active_infinite_column is None {
    guard self.take_queued_column() is Some(key) else { return [] }
    let (x, z) = @level.chunk_xz_by_chunk_column_key(key)
    self.active_infinite_column = Some(
      self.world.begin_infinite_chunk_column_generation(x, z),
    )
  }
  guard self.active_infinite_column is Some(generation) else { return [] }
  guard generation.advance(self.generation_work_budget) else { return [] }
  let key = generation.column_key()
  self.active_infinite_column = None
  guard self.desired_columns.contains(key) else { return [] }
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
    guard self.take_queued_column() is Some(key) else { break }
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
fn ChunkRuntime::mark_loaded_neighbor_boundaries_dirty(
  self : ChunkRuntime,
  x : Int,
  z : Int,
) -> Unit {
  for offset in [(-1, 0, 0), (1, 0, 0), (0, 0, -1), (0, 0, 1)] {
    let (dx, _, dz) = offset
    let column_key = @level.chunk_column_key_by_chunk_xz(x + dx, z + dz)
    if self.loaded_columns.contains(column_key) {
      self.mark_column_boundary_dirty(x + dx, z + dz, dx, dz)
    }
  }
}

///|
fn ChunkRuntime::apply_block_deltas(
  self : ChunkRuntime,
  chunk_key : String,
  data : Array[UInt],
) -> Unit {
  for delta in self.block_deltas.values() {
    guard chunk_key_by_world(self.chunk_size, delta.x, delta.y, delta.z) ==
      chunk_key else {
      continue
    }
    let cx = @util.floor_div(delta.x, self.chunk_size)
    let cy = @util.floor_div(delta.y, self.chunk_size)
    let cz = @util.floor_div(delta.z, self.chunk_size)
    let lx = delta.x - cx * self.chunk_size
    let ly = delta.y - cy * self.chunk_size
    let lz = delta.z - cz * self.chunk_size
    let index = (ly * self.chunk_size + lz) * self.chunk_size + lx
    if index >= 0 && index < data.length() {
      data[index] = delta.id
    }
  }
}

///|
fn ChunkRuntime::record_block_delta(
  self : ChunkRuntime,
  x : Int,
  y : Int,
  z : Int,
  id : UInt,
) -> Unit {
  self.block_deltas["\{x},\{y},\{z}"] = @level.BlockDelta::new(x, y, z, id)
}

///|
/// Restore one persisted voxel override and apply it immediately when its
/// chunk is already resident.
pub fn ChunkRuntime::load_block_delta(
  self : ChunkRuntime,
  x : Int,
  y : Int,
  z : Int,
  id : UInt,
) -> Unit {
  self.record_block_delta(x, y, z, id)
  let key = chunk_key_by_world(self.chunk_size, x, y, z)
  guard @level.get_chunk_data(self.chunk_map, key) is Some(data) else { return }
  self.apply_block_deltas(key, data)
  self.mark_block_changed(x, y, z)
}

///|
pub fn ChunkRuntime::block_deltas(
  self : ChunkRuntime,
) -> Array[@level.BlockDelta] {
  self.block_deltas.values().to_array()
}

///|
fn ChunkRuntime::evict_undesired(self : ChunkRuntime) -> Array[String] {
  let evicted : Array[String] = []
  let center_key = @level.chunk_column_key_by_chunk_xz(
    self.desired_center_x,
    self.desired_center_z,
  )
  guard self.loaded_columns.contains(center_key) else { return evicted }
  for key in self.loaded_columns.keys().to_array() {
    if self.desired_columns.contains(key) {
      continue
    }
    let (x, z) = @level.chunk_xz_by_chunk_column_key(key)
    self.mark_loaded_neighbor_boundaries_dirty(x, z)
    self.loaded_columns.remove(key)
    for y in self.chunk_min_y..<=self.chunk_max_y {
      let chunk_key = @level.chunk_key_by_chunk_xyz(x, y, z)
      self.remove_chunk_sections(chunk_key)
      self.dirty_lights.remove(chunk_key)
      self.lights.remove(chunk_key)
      ignore(@ffi.map_delete(self.chunk_map, chunk_key))
      evicted.push(chunk_key)
    }
  }
  evicted
}

///|
fn ChunkRuntime::remove_chunk_sections(
  self : ChunkRuntime,
  chunk_key : String,
) -> Unit {
  for sx in 0..<self.sections_per_axis {
    for sy in 0..<self.sections_per_axis {
      for sz in 0..<self.sections_per_axis {
        let key = section_key(chunk_key, sx, sy, sz)
        self.dirty_sections.remove(key)
        self.rendered_sections.remove(key)
      }
    }
  }
}

///|
fn ChunkRuntime::refresh_lights(self : ChunkRuntime) -> Array[String] {
  guard self.dirty_lights.length() > 0 else { return [] }
  if @level.USE_FIXED_LIGHT {
    self.dirty_lights = {}
    return []
  }
  let keys : Array[String] = []
  for column_key in self.desired_columns.keys() {
    let (x, z) = @level.chunk_xz_by_chunk_column_key(column_key)
    for y in self.chunk_min_y..<=self.chunk_max_y {
      keys.push(@level.chunk_key_by_chunk_xyz(x, y, z))
    }
  }
  guard keys.length() > 0 else { return [] }
  let updated : Array[String] = []
  for
    entry in @level.build_world_light(
      self.chunk_map,
      self.chunk_size,
      keys,
      self.world.min_y(),
      self.world.max_y(),
    ) {
    let (key, light) = entry
    self.lights[key] = light
    updated.push(key)
  }
  self.dirty_lights = {}
  updated
}

///|
fn ChunkRuntime::mark_section_by_world(
  self : ChunkRuntime,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Unit {
  let chunk_key = chunk_key_by_world(self.chunk_size, wx, wy, wz)
  let column_key = chunk_column_key_by_world(self.chunk_size, wx, wz)
  guard self.loaded_columns.contains(column_key) else { return }
  let (cx, cy, cz) = @level.chunk_xyz_by_chunk_key(chunk_key)
  let local_x = wx - cx * self.chunk_size
  let local_y = wy - cy * self.chunk_size
  let local_z = wz - cz * self.chunk_size
  let sx = @util.floor_div(local_x, self.section_size)
  let sy = @util.floor_div(local_y, self.section_size)
  let sz = @util.floor_div(local_z, self.section_size)
  guard sx >= 0 && sy >= 0 && sz >= 0 else { return }
  guard sx < self.sections_per_axis &&
    sy < self.sections_per_axis &&
    sz < self.sections_per_axis else {
    return
  }
  let section = ChunkSection::{ chunk_key, x: sx, y: sy, z: sz }
  self.dirty_sections[section_key(chunk_key, sx, sy, sz)] = section
}

///|
/// Return whether a section contains any non-air voxel in its core region.
/// Padded neighbor data is only needed for sections that can emit geometry.
fn ChunkRuntime::section_has_non_air(
  self : ChunkRuntime,
  section : ChunkSection,
) -> Bool {
  guard @level.get_chunk_data(self.chunk_map, section.chunk_key) is Some(data) else {
    false
  }
  let base_x = section.x * self.section_size
  let base_y = section.y * self.section_size
  let base_z = section.z * self.section_size
  for y in base_y..<(base_y + self.section_size) {
    for z in base_z..<(base_z + self.section_size) {
      for x in base_x..<(base_x + self.section_size) {
        let index = (y * self.chunk_size + z) * self.chunk_size + x
        guard data[index] == @block.AIR_LONG_ID else { return true }
      }
    }
  }
  false
}

///|
fn ChunkRuntime::mark_section_dirty(
  self : ChunkRuntime,
  chunk_key : String,
  sx : Int,
  sy : Int,
  sz : Int,
) -> Unit {
  let section = ChunkSection::{ chunk_key, x: sx, y: sy, z: sz }
  let key = section_key(chunk_key, sx, sy, sz)
  guard self.section_has_non_air(section) ||
    self.rendered_sections.contains(key) else {
    return
  }
  self.dirty_sections[key] = section
}

///|
fn ChunkRuntime::mark_chunk_sections_dirty(
  self : ChunkRuntime,
  chunk_key : String,
) -> Unit {
  for sx in 0..<self.sections_per_axis {
    for sy in 0..<self.sections_per_axis {
      for sz in 0..<self.sections_per_axis {
        self.mark_section_dirty(chunk_key, sx, sy, sz)
      }
    }
  }
}

///|
fn ChunkRuntime::mark_column_boundary_dirty(
  self : ChunkRuntime,
  x : Int,
  z : Int,
  dx : Int,
  dz : Int,
) -> Unit {
  let max_section = self.sections_per_axis - 1
  for y in self.chunk_min_y..<=self.chunk_max_y {
    let chunk_key = @level.chunk_key_by_chunk_xyz(x, y, z)
    if dx != 0 {
      let sx = if dx < 0 { max_section } else { 0 }
      for sy in 0..<self.sections_per_axis {
        for sz in 0..<self.sections_per_axis {
          self.mark_section_dirty(chunk_key, sx, sy, sz)
        }
      }
    } else {
      let sz = if dz < 0 { max_section } else { 0 }
      for sx in 0..<self.sections_per_axis {
        for sy in 0..<self.sections_per_axis {
          self.mark_section_dirty(chunk_key, sx, sy, sz)
        }
      }
    }
    self.dirty_lights[chunk_key] = true
  }
}

///|
fn ChunkRuntime::mark_column_chunks_dirty(
  self : ChunkRuntime,
  x : Int,
  z : Int,
) -> Unit {
  for y in self.chunk_min_y..<=self.chunk_max_y {
    let key = @level.chunk_key_by_chunk_xyz(x, y, z)
    self.mark_chunk_sections_dirty(key)
    self.dirty_lights[key] = true
  }
}

///|
fn ChunkRuntime::section_data(
  self : ChunkRuntime,
  section : ChunkSection,
) -> Array[UInt] {
  let (cx, cy, cz) = @level.chunk_xyz_by_chunk_key(section.chunk_key)
  let base_x = (cx * self.sections_per_axis + section.x) * self.section_size
  let base_y = (cy * self.sections_per_axis + section.y) * self.section_size
  let base_z = (cz * self.sections_per_axis + section.z) * self.section_size
  let pad = self.section_size + 2
  let data : Array[UInt] = []
  for y in -1..<=self.section_size {
    for z in -1..<=self.section_size {
      for x in -1..<=self.section_size {
        data.push(
          @level.get_block_id(
            self.chunk_map,
            self.chunk_size,
            base_x + x,
            base_y + y,
            base_z + z,
          ).unwrap_or(@block.AIR_LONG_ID),
        )
      }
    }
  }
  guard data.length() == pad * pad * pad else { abort("invalid section data") }
  data
}

///|
fn ChunkRuntime::section_light(
  self : ChunkRuntime,
  section : ChunkSection,
) -> Bytes {
  let cell_count = self.section_size * self.section_size * self.section_size
  guard !@level.USE_FIXED_LIGHT else { return self.fixed_section_light }
  guard self.lights.get(section.chunk_key) is Some(chunk_light) else {
    return Bytes::make(cell_count, 15)
  }
  let chunk_cell_count = self.chunk_size * self.chunk_size * self.chunk_size
  let chunk_pad = self.chunk_size + 2
  let chunk_pad_count = chunk_pad * chunk_pad * chunk_pad
  guard chunk_light.length() == chunk_cell_count ||
    chunk_light.length() == chunk_pad_count else {
    return Bytes::make(cell_count, 15)
  }
  let offset_x = section.x * self.section_size
  let offset_y = section.y * self.section_size
  let offset_z = section.z * self.section_size
  let light : Array[Byte] = []
  for y in 0..<self.section_size {
    for z in 0..<self.section_size {
      for x in 0..<self.section_size {
        let lx = offset_x + x
        let ly = offset_y + y
        let lz = offset_z + z
        let index = if chunk_light.length() == chunk_cell_count {
          (ly * self.chunk_size + lz) * self.chunk_size + lx
        } else {
          ((ly + 1) * chunk_pad + (lz + 1)) * chunk_pad + lx + 1
        }
        light.push(chunk_light[index])
      }
    }
  }
  Bytes::from_array(light)
}

///|
fn ChunkRuntime::section_entry(
  self : ChunkRuntime,
  section : ChunkSection,
) -> ChunkEntry {
  let (cx, cy, cz) = @level.chunk_xyz_by_chunk_key(section.chunk_key)
  {
    x: cx * self.sections_per_axis + section.x,
    y: cy * self.sections_per_axis + section.y,
    z: cz * self.sections_per_axis + section.z,
    data: self.section_data(section),
    light: self.section_light(section),
  }
}

///|
fn ChunkRuntime::build_mesh_command(
  self : ChunkRuntime,
  registry : BlockRegistry,
  section : ChunkSection,
) -> ChunkMeshCommand {
  let entry = self.section_entry(section)
  let half = self.section_size.to_double() * 0.5
  self.rendered_sections[section_key(
    section.chunk_key,
    section.x,
    section.y,
    section.z,
  )] = section
  {
    chunk_key: section.chunk_key,
    x: section.x,
    y: section.y,
    z: section.z,
    center_x: (entry.x * self.section_size).to_double() + half,
    center_y: (entry.y * self.section_size).to_double() + half,
    center_z: (entry.z * self.section_size).to_double() + half,
    mesh: build_world_mesh_split(registry, [entry], self.section_size),
  }
}

///|
fn ChunkRuntime::build_recolor_commands(
  self : ChunkRuntime,
  registry : BlockRegistry,
  relit_chunks : Array[String],
  mesh_updates : Array[ChunkMeshCommand],
) -> Array[ChunkRecolorCommand] {
  let relit : Map[String, Bool] = Map([])
  for key in relit_chunks {
    relit[key] = true
  }
  let rebuilt : Map[String, Bool] = Map([])
  for command in mesh_updates {
    rebuilt[section_key(command.chunk_key, command.x, command.y, command.z)] = true
  }
  let commands : Array[ChunkRecolorCommand] = []
  for key, section in self.rendered_sections {
    guard relit.contains(section.chunk_key) && !rebuilt.contains(key) else {
      continue
    }
    let entry = self.section_entry(section)
    commands.push({
      chunk_key: section.chunk_key,
      x: section.x,
      y: section.y,
      z: section.z,
      colors: build_chunk_colors_split(
        registry,
        entry.data,
        entry.light,
        self.section_size,
      ),
    })
  }
  commands
}

///|
/// Record a voxel mutation already applied to `chunk_map`, invalidating every
/// section that can expose a changed face and the affected lighting region.
pub fn ChunkRuntime::mark_block_changed(
  self : ChunkRuntime,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Unit {
  for
    offset in [
      (0, 0, 0),
      (-1, 0, 0),
      (1, 0, 0),
      (0, -1, 0),
      (0, 1, 0),
      (0, 0, -1),
      (0, 0, 1),
    ] {
    let (dx, dy, dz) = offset
    self.mark_section_by_world(wx + dx, wy + dy, wz + dz)
  }
  let key = chunk_key_by_world(self.chunk_size, wx, wy, wz)
  let column_key = chunk_column_key_by_world(self.chunk_size, wx, wz)
  if self.loaded_columns.contains(column_key) {
    self.dirty_lights[key] = true
  }
  match @level.get_block_id(self.chunk_map, self.chunk_size, wx, wy, wz) {
    Some(id) => self.record_block_delta(wx, wy, wz, id)
    None => ()
  }
}
