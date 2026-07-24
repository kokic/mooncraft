///|
pub const CHUNK_RENDER_DISTANCE : Int = 2

///|
pub const CHUNK_SECTION_SIZE : Int = 8

///|
pub const CHUNK_GENERATION_BUDGET : Int = 2

///|
pub const CHUNK_MESH_BUDGET : Int = 8

///|
/// Persistent voxel override applied after procedural generation.
pub struct BlockDelta {
  x : Int
  y : Int
  z : Int
  id : UInt
} derive(Debug, ToJson, FromJson)

///|
pub fn BlockDelta::new(x : Int, y : Int, z : Int, id : UInt) -> BlockDelta {
  { x, y, z, id }
}

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
  mesh_budget : Int
  loaded : Map[String, Bool]
  mut desired : Map[String, Bool]
  queued : Map[String, Bool]
  mut queue : Array[String]
  mut queue_head : Int
  dirty_sections : Map[String, ChunkSection]
  rendered_sections : Map[String, ChunkSection]
  mut dirty_lights : Map[String, Bool]
  lights : Map[String, Bytes]
  block_deltas : Map[String, BlockDelta]
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
pub fn ChunkRuntime::new(
  world : @level.World,
  initial_chunk : Array[UInt],
  render_distance? : Int = CHUNK_RENDER_DISTANCE,
  section_size? : Int = CHUNK_SECTION_SIZE,
  generation_budget? : Int = CHUNK_GENERATION_BUDGET,
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
  let loaded : Map[String, Bool] = Map([])
  let dirty_lights : Map[String, Bool] = Map([])
  // Spawn surface selection needs a complete column before the first frame.
  for cy in chunk_min_y..<=chunk_max_y {
    let key = @level.chunk_key_by_chunk_xyz(spawn_chunk_x, cy, spawn_chunk_z)
    let data = if spawn_chunk_x == 0 && cy == 0 && spawn_chunk_z == 0 {
      initial_chunk
    } else {
      world.generate_chunk(spawn_chunk_x, cy, spawn_chunk_z).tile_map
    }
    @ffi.map_set_value(chunk_map, key, data)
    loaded[key] = true
    dirty_lights[key] = true
  }
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
    mesh_budget: if mesh_budget < 1 {
      1
    } else {
      mesh_budget
    },
    loaded,
    desired: {},
    queued: {},
    queue: [],
    queue_head: 0,
    dirty_sections: {},
    rendered_sections: {},
    dirty_lights,
    lights: {},
    block_deltas: {},
  }
  for key in loaded.keys() {
    runtime.mark_chunk_sections_dirty(key)
  }
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
fn ChunkRuntime::enqueue(self : ChunkRuntime, key : String) -> Unit {
  guard !self.loaded.contains(key) && !self.queued.contains(key) else { return }
  self.queued[key] = true
  self.queue.push(key)
}

///|
fn ChunkRuntime::refresh_desired(
  self : ChunkRuntime,
  center_x : Int,
  center_z : Int,
) -> Unit {
  self.desired = {}
  for
    key in collect_render_chunk_keys(
      center_x,
      center_z,
      self.render_distance,
      self.chunk_min_y,
      self.chunk_max_y,
    ) {
    self.desired[key] = true
    self.enqueue(key)
  }
}

///|
fn ChunkRuntime::generate_queued(self : ChunkRuntime) -> Array[String] {
  let generated : Array[String] = []
  let mut remaining = self.generation_budget
  while remaining > 0 && self.queue_head < self.queue.length() {
    let key = self.queue[self.queue_head]
    self.queue_head = self.queue_head + 1
    self.queued.remove(key)
    if self.loaded.contains(key) || !self.desired.contains(key) {
      continue
    }
    let (x, y, z) = @level.chunk_xyz_by_chunk_key(key)
    let data = self.world.generate_chunk(x, y, z).tile_map
    self.apply_block_deltas(key, data)
    @ffi.map_set_value(self.chunk_map, key, data)
    self.loaded[key] = true
    self.mark_chunk_sections_dirty(key)
    self.dirty_lights[key] = true
    self.mark_loaded_neighbors_dirty(x, y, z)
    generated.push(key)
    remaining = remaining - 1
  }
  if self.queue_head >= self.queue.length() {
    self.queue = []
    self.queue_head = 0
  }
  generated
}

///|
fn ChunkRuntime::mark_loaded_neighbors_dirty(
  self : ChunkRuntime,
  x : Int,
  y : Int,
  z : Int,
) -> Unit {
  for
    offset in [
      (-1, 0, 0),
      (1, 0, 0),
      (0, -1, 0),
      (0, 1, 0),
      (0, 0, -1),
      (0, 0, 1),
    ] {
    let (dx, dy, dz) = offset
    let key = @level.chunk_key_by_chunk_xyz(x + dx, y + dy, z + dz)
    if self.loaded.contains(key) {
      self.mark_chunk_sections_dirty(key)
      self.dirty_lights[key] = true
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
  self.block_deltas["\{x},\{y},\{z}"] = BlockDelta::{ x, y, z, id }
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
pub fn ChunkRuntime::block_deltas(self : ChunkRuntime) -> Array[BlockDelta] {
  self.block_deltas.values().to_array()
}

///|
fn ChunkRuntime::evict_undesired(self : ChunkRuntime) -> Array[String] {
  let evicted : Array[String] = []
  for key in self.loaded.keys().to_array() {
    if self.desired.contains(key) {
      continue
    }
    let (x, y, z) = @level.chunk_xyz_by_chunk_key(key)
    self.mark_loaded_neighbors_dirty(x, y, z)
    self.loaded.remove(key)
    self.remove_chunk_sections(key)
    self.dirty_lights.remove(key)
    self.lights.remove(key)
    ignore(@ffi.map_delete(self.chunk_map, key))
    evicted.push(key)
  }
  evicted
}

///|
fn ChunkRuntime::remove_chunk_sections(
  self : ChunkRuntime,
  chunk_key : String,
) -> Unit {
  for key in self.dirty_sections.keys().to_array() {
    guard self.dirty_sections.get(key) is Some(section) else { continue }
    if section.chunk_key == chunk_key {
      self.dirty_sections.remove(key)
    }
  }
  for key in self.rendered_sections.keys().to_array() {
    guard self.rendered_sections.get(key) is Some(section) else { continue }
    if section.chunk_key == chunk_key {
      self.rendered_sections.remove(key)
    }
  }
}

///|
fn ChunkRuntime::refresh_lights(self : ChunkRuntime) -> Array[String] {
  guard self.dirty_lights.length() > 0 else { return [] }
  let keys = self.desired.keys().to_array()
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
  guard self.loaded.contains(chunk_key) else { return }
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
fn ChunkRuntime::mark_chunk_sections_dirty(
  self : ChunkRuntime,
  chunk_key : String,
) -> Unit {
  for sx in 0..<self.sections_per_axis {
    for sy in 0..<self.sections_per_axis {
      for sz in 0..<self.sections_per_axis {
        let section = ChunkSection::{ chunk_key, x: sx, y: sy, z: sz }
        self.dirty_sections[section_key(chunk_key, sx, sy, sz)] = section
      }
    }
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
  guard !@level.USE_FIXED_LIGHT else { return Bytes::make(cell_count, 15) }
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
  if self.loaded.contains(key) {
    self.dirty_lights[key] = true
  }
  match @level.get_block_id(self.chunk_map, self.chunk_size, wx, wy, wz) {
    Some(id) => self.record_block_delta(wx, wy, wz, id)
    None => ()
  }
}
