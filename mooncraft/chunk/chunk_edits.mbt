///|
/// Set one loaded world block and synchronize every runtime concern that
/// depends on its contents. Returns `false` when the target chunk is absent.
pub fn ChunkRuntime::set_block(
  self : ChunkRuntime,
  wx : Int,
  wy : Int,
  wz : Int,
  id : UInt,
) -> Bool {
  guard @level.get_block_id(self.chunk_map, self.chunk_size, wx, wy, wz)
    is Some(current_id) else {
    false
  }
  guard current_id != id else { true }
  ignore(@level.set_block_id(self.chunk_map, self.chunk_size, wx, wy, wz, id))
  self.mark_block_changed(wx, wy, wz)
  true
}

///|
/// Apply a structure's block changes only when every target chunk is loaded.
/// This keeps multi-block placement from producing a partial structure at a
/// streaming boundary.
pub fn ChunkRuntime::apply_block_deltas(
  self : ChunkRuntime,
  deltas : Array[@level.BlockDelta],
) -> Bool {
  for delta in deltas {
    guard @level.get_block_id(
        self.chunk_map,
        self.chunk_size,
        delta.x,
        delta.y,
        delta.z,
      )
      is Some(_) else {
      return false
    }
  }
  for delta in deltas {
    ignore(
      self.set_block(
        delta.x,
        delta.y,
        delta.z,
        @block.name_to_internal_id(delta.id),
      ),
    )
  }
  true
}

///|
fn ChunkRuntime::record_block_delta(
  self : ChunkRuntime,
  x : Int,
  y : Int,
  z : Int,
  id : UInt,
) -> Unit {
  let name = @block.lookup_by_internal_id(id)
    .map(b => b.name)
    .unwrap_or(@schema.AIR_NAME)
  self.edits.record(self.chunk_size, @level.BlockDelta::new(x, y, z, name))
}

///|
/// Restore one persisted voxel override and apply it immediately when its
/// chunk is already resident.
pub fn ChunkRuntime::load_block_delta(
  self : ChunkRuntime,
  x : Int,
  y : Int,
  z : Int,
  id : String,
) -> Unit {
  self.edits.record(self.chunk_size, @level.BlockDelta::new(x, y, z, id))
  let address = @level.BlockAddress::new(self.chunk_size, x, y, z)
  guard self.chunk_map.get(address.chunk_key()) is Some(data) else { () }
  data[address.index(self.chunk_size)] = @block.name_to_internal_id(id)
  self.mark_block_changed(x, y, z)
}
///|
pub fn ChunkRuntime::block_deltas(
  self : ChunkRuntime,
) -> Array[@level.BlockDelta] {
  self.edits.snapshot()
}

///|
/// Discard every persisted voxel override. Used when a region is rebuilt from
/// scratch (design reset) so stale overrides cannot resurrect removed blocks.
pub fn ChunkRuntime::clear_block_edits(self : ChunkRuntime) -> Unit {
  self.edits = BlockEdits::new()
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
  if self.streaming.loaded_columns.contains(column_key) {
    self.lighting.dirty_lights[key] = true
  }
  guard @level.get_block_id(self.chunk_map, self.chunk_size, wx, wy, wz)
    is Some(id) else {
    ()
  }
  if self.lighting.light_cache.update_block(wx, wy, wz, id) {
    let (cx, _, cz) = @level.chunk_xyz_by_chunk_key(key)
    for cy in self.chunk_min_y..<=self.chunk_max_y {
      self.lighting.dirty_lights[@level.chunk_key_by_chunk_xyz(cx, cy, cz)] = true
    }
  }
  self.record_block_delta(wx, wy, wz, id)
}
