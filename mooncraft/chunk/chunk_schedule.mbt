///|
/// Collect chunk keys for render distance around the center chunk.
/// The iteration order matches JS-side scheduling for predictable caching.
pub fn collect_render_chunk_keys(
  center_x : Int,
  center_z : Int,
  render_distance : Int,
  chunk_min_y : Int,
  chunk_max_y : Int,
) -> Array[String] {
  let keys : Array[String] = []
  for_render_columns(center_x, center_z, render_distance, (x, z) => {
    for y in chunk_min_y..<=chunk_max_y {
      keys.push(@level.chunk_key_by_chunk_xyz(x, y, z))
    }
  })
  keys
}
///|
pub fn collect_render_column_keys(
  center_x : Int,
  center_z : Int,
  render_distance : Int,
) -> Array[String] {
  let keys : Array[String] = []
  for_render_columns(center_x, center_z, render_distance, (x, z) => {
    keys.push(@level.chunk_column_key_by_chunk_xz(x, z))
  })
  keys
}
///|
fn ChunkRuntime::take_dirty_sections(
  self : ChunkRuntime,
) -> Array[ChunkSection] {
  guard self.meshes.dirty_sections.length() > 0 else { return [] }
  let sections : Array[ChunkSection] = []
  let mut remaining = self.mesh_budget
  for
    chunk_key in collect_render_chunk_keys(
      self.streaming.desired_center_x,
      self.streaming.desired_center_z,
      self.render_distance,
      self.chunk_min_y,
      self.chunk_max_y,
    ) {
    guard self.light_ready(chunk_key) else { continue }
    for sx in 0..<self.sections_per_axis {
      for sy in 0..<self.sections_per_axis {
        for sz in 0..<self.sections_per_axis {
          if remaining == 0 {
            return sections
          }
          let key = section_key(chunk_key, sx, sy, sz)
          guard self.meshes.dirty_sections.get(key) is Some(section) else { continue }
          self.meshes.dirty_sections.remove(key)
          guard self.section_in_mesh_window(section) else { continue }
          sections.push(section)
          remaining = remaining - 1
        }
      }
    }
  }
  sections
}

///|
/// Advance chunk streaming and lighting. The returned frame is the only work
/// the browser renderer is allowed to perform for world CPU state this frame.
pub fn ChunkRuntime::tick(
  self : ChunkRuntime,
  registry : @block.RenderRegistry,
  center_x : Int,
  center_z : Int,
  center_y? : Int = 0,
) -> ChunkRenderFrame {
  self.refresh_mesh_window(center_y)
  self.streaming.refresh_desired(center_x, center_z, self.render_distance)
  let generated = self.generate_queued()
  let evicted = self.evict_undesired()
  let relit = self.refresh_lights()
  let sections = self.take_dirty_sections()
  let mesh_updates = sections.map(section => {
    self.build_mesh_command(registry, section)
  })
  let recolors = self.build_recolor_commands(registry, relit, mesh_updates)
  { generated, evicted, mesh_updates, recolors, }
}
///|
/// Visit columns from the center outward in the shared scheduling order.
fn for_render_columns(
  center_x : Int,
  center_z : Int,
  render_distance : Int,
  visit : (Int, Int) -> Unit,
) -> Unit {
  for ring in 0..<=render_distance {
    for dx in -ring..<=ring {
      for dz in -ring..<=ring {
        guard dx.abs() == ring || dz.abs() == ring else { continue }
        visit(center_x + dx, center_z + dz)
      }
    }
  }
}
