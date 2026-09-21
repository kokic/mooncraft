///|
fn ChunkRuntime::section_data(
  self : ChunkRuntime,
  section : ChunkSection,
) -> Array[UInt] {
  let (cx, cy, cz) = @level.chunk_xyz_by_chunk_key(section.chunk_key)
  let base_x = (cx * self.sections_per_axis + section.x) * self.section_size
  let base_y = (cy * self.sections_per_axis + section.y) * self.section_size
  let base_z = (cz * self.sections_per_axis + section.z) * self.section_size
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
          ).unwrap_or(@schema.AIR_ID),
        )
      }
    }
  }
  data
}

///|
fn ChunkRuntime::section_light(
  self : ChunkRuntime,
  section : ChunkSection,
) -> Bytes {
  let pad = self.section_size + 2
  let cell_count = pad * pad * pad
  guard !@level.USE_FIXED_LIGHT else { return self.lighting.fixed_section_light }
  guard self.lighting.lights.get(section.chunk_key) is Some(chunk_light) else {
    return Bytes::make(cell_count, 15)
  }
  let chunk_pad = self.chunk_size + 2
  let chunk_pad_count = chunk_pad * chunk_pad * chunk_pad
  guard chunk_light.length() == chunk_pad_count else {
    return Bytes::make(cell_count, 15)
  }
  let offset_x = section.x * self.section_size
  let offset_y = section.y * self.section_size
  let offset_z = section.z * self.section_size
  let light : Array[Byte] = []
  // Preserve the neighbor layer used to shade faces on section boundaries.
  for y in 0..<pad {
    for z in 0..<pad {
      for x in 0..<pad {
        let lx = offset_x + x
        let ly = offset_y + y
        let lz = offset_z + z
        let index = (ly * chunk_pad + lz) * chunk_pad + lx
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
) -> @mesh.ChunkEntry {
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
  registry : @block.RenderRegistry,
  section : ChunkSection,
) -> ChunkMeshCommand {
  let entry = self.section_entry(section)
  let half = self.section_size.to_double() * 0.5
  self.meshes.rendered_sections[section_key(
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
    mesh: @mesh.build_world_mesh_split(registry, [entry], self.section_size),
  }
}

///|
fn ChunkRuntime::build_recolor_commands(
  self : ChunkRuntime,
  registry : @block.RenderRegistry,
  relit_chunks : Array[String],
  mesh_updates : Array[ChunkMeshCommand],
) -> Array[ChunkRecolorCommand] {
  let relit : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  for key in relit_chunks {
    relit[key] = true
  }
  if relit.length() > 0 {
    for key, section in self.meshes.rendered_sections {
      if relit.contains(section.chunk_key) {
        self.meshes.dirty_colors[key] = section
      }
    }
  }
  for command in mesh_updates {
    self.meshes.dirty_colors.remove(
      section_key(command.chunk_key, command.x, command.y, command.z),
    )
  }
  let commands : Array[ChunkRecolorCommand] = []
  for key in self.meshes.dirty_colors.keys().to_array() {
    guard commands.length() + mesh_updates.length() < self.mesh_budget else {
      break
    }
    // A pending geometry rebuild will also supply fresh colors. Recoloring
    // it now could upload a color buffer with a different vertex count.
    guard !self.meshes.dirty_sections.contains(key) else { continue }
    guard self.meshes.dirty_colors.get(key) is Some(section) else { continue }
    self.meshes.dirty_colors.remove(key)
    let entry = self.section_entry(section)
    commands.push({
      chunk_key: section.chunk_key,
      x: section.x,
      y: section.y,
      z: section.z,
      colors: @mesh.build_chunk_colors_split(
        registry,
        entry.data,
        entry.light,
        self.section_size,
      ),
    })
  }
  commands
}
