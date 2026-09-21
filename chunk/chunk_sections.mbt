///|
priv struct SectionMeshes {
  mut mesh_min_y : Int
  mut mesh_max_y : Int
  dirty_sections : @hashmap.HashMap[String, ChunkSection]
  rendered_sections : @hashmap.HashMap[String, ChunkSection]
  dirty_colors : @hashmap.HashMap[String, ChunkSection]
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
    if self.streaming.loaded_columns.contains(column_key) {
      self.mark_column_boundary_dirty(x + dx, z + dz, dx, dz)
    }
  }
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
        self.meshes.dirty_sections.remove(key)
        self.meshes.rendered_sections.remove(key)
        self.meshes.dirty_colors.remove(key)
      }
    }
  }
}

///|
fn ChunkRuntime::mark_section_by_world(
  self : ChunkRuntime,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Unit {
  let address = @level.BlockAddress::new(self.chunk_size, wx, wy, wz)
  let chunk_key = address.chunk_key()
  guard self.streaming.loaded_columns.contains(address.column_key()) else { () }
  let sx = address.x / self.section_size
  let sy = address.y / self.section_size
  let sz = address.z / self.section_size
  let section = ChunkSection::{ chunk_key, x: sx, y: sy, z: sz, }
  self.meshes.dirty_sections[section_key(chunk_key, sx, sy, sz)] = section
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
        guard data[index] == @schema.AIR_ID else { return true }
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
  let section = ChunkSection::{ chunk_key, x: sx, y: sy, z: sz, }
  guard self.section_in_mesh_window(section) else { return }
  let key = section_key(chunk_key, sx, sy, sz)
  guard self.section_has_non_air(section) ||
    self.meshes.rendered_sections.contains(key) else {
    return
  }
  self.meshes.dirty_sections[key] = section
}

///|
fn ChunkRuntime::section_in_mesh_window(
  self : ChunkRuntime,
  section : ChunkSection,
) -> Bool {
  let (_, chunk_y, _) = @level.chunk_xyz_by_chunk_key(section.chunk_key)
  let section_min_y = chunk_y * self.chunk_size + section.y * self.section_size
  let section_max_y = section_min_y + self.section_size - 1
  section_max_y >= self.meshes.mesh_min_y && section_min_y <= self.meshes.mesh_max_y
}

///|
fn ChunkRuntime::refresh_mesh_window(
  self : ChunkRuntime,
  center_y : Int,
) -> Unit {
  self.lighting.light_center_y = center_y
  let min_y = (center_y - VERTICAL_MESH_RADIUS).clamp(
    min=self.world.min_y(),
    max=self.world.max_y(),
  )
  let max_y = (center_y + VERTICAL_MESH_RADIUS).clamp(
    min=self.world.min_y(),
    max=self.world.max_y(),
  )
  guard min_y != self.meshes.mesh_min_y || max_y != self.meshes.mesh_max_y else { return }
  let old_min_section = @util.floor_div(self.meshes.mesh_min_y, self.section_size)
  let old_max_section = @util.floor_div(self.meshes.mesh_max_y, self.section_size)
  self.meshes.mesh_min_y = min_y
  self.meshes.mesh_max_y = max_y
  let min_section = @util.floor_div(min_y, self.section_size)
  let max_section = @util.floor_div(max_y, self.section_size)
  guard min_section != old_min_section || max_section != old_max_section else {
    return
  }
  for key in self.meshes.dirty_sections.keys().to_array() {
    guard self.meshes.dirty_sections.get(key) is Some(section) else { continue }
    if !self.section_in_mesh_window(section) {
      self.meshes.dirty_sections.remove(key)
    }
  }
  for column_key in self.streaming.loaded_columns.keys() {
    let (x, z) = @level.chunk_xz_by_chunk_column_key(column_key)
    for section_y in min_section..<=max_section {
      guard section_y < old_min_section || section_y > old_max_section else {
        continue
      }
      let cy = @util.floor_div(section_y, self.sections_per_axis)
      let sy = section_y - cy * self.sections_per_axis
      let key = @level.chunk_key_by_chunk_xyz(x, cy, z)
      self.lighting.dirty_lights[key] = true
      for sx in 0..<self.sections_per_axis {
        for sz in 0..<self.sections_per_axis {
          self.mark_section_dirty(key, sx, sy, sz)
        }
      }
    }
  }
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
    self.lighting.dirty_lights[chunk_key] = true
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
    self.lighting.dirty_lights[key] = true
  }
}

///|
/// Mark every resident section dirty and re-light loaded columns. Used after a
/// wholesale region rewrite where per-voxel notifications are impractical.
pub fn ChunkRuntime::invalidate_loaded_sections(self : ChunkRuntime) -> Unit {
  for key in self.meshes.rendered_sections.keys().to_array() {
    guard self.meshes.rendered_sections.get(key) is Some(section) else {
      continue
    }
    self.meshes.dirty_sections[key] = section
  }
  for column_key in self.streaming.loaded_columns.keys() {
    let (x, z) = @level.chunk_xz_by_chunk_column_key(column_key)
    for y in self.chunk_min_y..<=self.chunk_max_y {
      self.lighting.dirty_lights[@level.chunk_key_by_chunk_xyz(x, y, z)] = true
    }
  }
}

///|
fn SectionMeshes::new(min_y : Int, max_y : Int) -> SectionMeshes {
  {
    mesh_min_y: min_y,
    mesh_max_y: max_y,
    dirty_sections: @hashmap.HashMap([]),
    rendered_sections: @hashmap.HashMap([]),
    dirty_colors: @hashmap.HashMap([]),
  }
}
