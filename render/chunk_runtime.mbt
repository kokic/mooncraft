///|
/// A mesh section addressed relative to its owning level chunk.
pub struct ChunkSection {
  chunk_key : String
  x : Int
  y : Int
  z : Int
} derive(Debug, ToJson)

///|
/// Persistent voxel override applied after procedural generation.
pub struct BlockDelta {
  x : Int
  y : Int
  z : Int
  id : UInt
} derive(Debug, ToJson)

///|
pub fn BlockDelta::new(x : Int, y : Int, z : Int, id : UInt) -> BlockDelta {
  { x, y, z, id }
}

///|
/// Work emitted by one world-runtime tick.  The browser executes these commands
/// by creating, replacing, recoloring, or disposing WebGL resources.
pub struct ChunkScheduleFrame {
  generated : Array[String]
  evicted : Array[String]
  full_rebuilds : Array[String]
  section_rebuilds : Array[ChunkSection]
  recolors : Array[String]
} derive(Debug)

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
  mut dirty_full : Map[String, Bool]
  mut dirty_sections : Map[String, ChunkSection]
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
  render_distance? : Int = 2,
  section_size? : Int = 8,
  generation_budget? : Int = 2,
  mesh_budget? : Int = 2,
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
  let dirty_full : Map[String, Bool] = Map([])
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
    dirty_full[key] = true
    dirty_lights[key] = true
  }
  {
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
    dirty_full,
    dirty_sections: {},
    dirty_lights,
    lights: {},
    block_deltas: {},
  }
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
    self.dirty_full[key] = true
    self.dirty_lights[key] = true
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
    self.loaded.remove(key)
    self.dirty_full.remove(key)
    self.dirty_lights.remove(key)
    self.lights.remove(key)
    ignore(@ffi.map_delete(self.chunk_map, key))
    evicted.push(key)
  }
  evicted
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
fn ChunkRuntime::take_full_rebuilds(self : ChunkRuntime) -> Array[String] {
  let keys = self.dirty_full.keys().to_array()
  self.dirty_full = {}
  keys
}

///|
fn ChunkRuntime::take_section_rebuilds(
  self : ChunkRuntime,
) -> Array[ChunkSection] {
  let sections = self.dirty_sections.values().to_array()
  self.dirty_sections = {}
  sections
}

///|
/// Advance chunk streaming and lighting. The returned frame is the only work
/// the browser renderer is allowed to perform for world CPU state this frame.
pub fn ChunkRuntime::tick(
  self : ChunkRuntime,
  center_x : Int,
  center_z : Int,
) -> ChunkScheduleFrame {
  self.refresh_desired(center_x, center_z)
  let generated = self.generate_queued()
  let evicted = self.evict_undesired()
  let recolors = self.refresh_lights()
  {
    generated,
    evicted,
    full_rebuilds: self.take_full_rebuilds(),
    section_rebuilds: self.take_section_rebuilds(),
    recolors,
  }
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
