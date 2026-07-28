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
  for ring in 0..<=render_distance {
    for dx in -ring..<=ring {
      for dz in -ring..<=ring {
        guard dx.abs() == ring || dz.abs() == ring else { continue }
        for cy in chunk_min_y..<=chunk_max_y {
          keys.push(
            @level.chunk_key_by_chunk_xyz(center_x + dx, cy, center_z + dz),
          )
        }
      }
    }
  }
  keys
}

///|
pub fn collect_render_column_keys(
  center_x : Int,
  center_z : Int,
  render_distance : Int,
) -> Array[String] {
  let keys : Array[String] = []
  for ring in 0..<=render_distance {
    for dx in -ring..<=ring {
      for dz in -ring..<=ring {
        guard dx.abs() == ring || dz.abs() == ring else { continue }
        keys.push(
          @level.chunk_column_key_by_chunk_xz(center_x + dx, center_z + dz),
        )
      }
    }
  }
  keys
}

///|
/// A mesh section addressed relative to its owning level chunk.
pub struct ChunkSection {
  chunk_key : String
  x : Int
  y : Int
  z : Int
} derive(Debug, ToJson)

///|
/// One MoonBit-prepared mesh upload for a level section.
pub struct ChunkMeshCommand {
  chunk_key : String
  x : Int
  y : Int
  z : Int
  center_x : Double
  center_y : Double
  center_z : Double
  mesh : MeshSplit
}

///|
/// One MoonBit-prepared color-buffer update for a rendered section.
pub struct ChunkRecolorCommand {
  chunk_key : String
  x : Int
  y : Int
  z : Int
  colors : MeshColorsSplit
}

///|
/// Work emitted by one world-runtime tick. The browser executes these commands
/// only by creating, replacing, recoloring, or disposing WebGL resources.
pub struct ChunkRenderFrame {
  generated : Array[String]
  evicted : Array[String]
  mesh_updates : Array[ChunkMeshCommand]
  recolors : Array[ChunkRecolorCommand]
}

///|
fn ChunkRuntime::take_dirty_sections(
  self : ChunkRuntime,
) -> Array[ChunkSection] {
  guard self.dirty_sections.length() > 0 else { return [] }
  let sections : Array[ChunkSection] = []
  let mut remaining = self.mesh_budget
  for
    chunk_key in collect_render_chunk_keys(
      self.desired_center_x,
      self.desired_center_z,
      self.render_distance,
      self.chunk_min_y,
      self.chunk_max_y,
    ) {
    for sx in 0..<self.sections_per_axis {
      for sy in 0..<self.sections_per_axis {
        for sz in 0..<self.sections_per_axis {
          if remaining == 0 {
            return sections
          }
          let key = section_key(chunk_key, sx, sy, sz)
          guard self.dirty_sections.get(key) is Some(section) else { continue }
          self.dirty_sections.remove(key)
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
  registry : BlockRegistry,
  center_x : Int,
  center_z : Int,
) -> ChunkRenderFrame {
  self.refresh_desired(center_x, center_z)
  let generated = self.generate_queued()
  let evicted = self.evict_undesired()
  let relit = self.refresh_lights()
  let sections = self.take_dirty_sections()
  let mesh_updates = sections.map(section => {
    self.build_mesh_command(registry, section)
  })
  let recolors = self.build_recolor_commands(registry, relit, mesh_updates)
  { generated, evicted, mesh_updates, recolors }
}
