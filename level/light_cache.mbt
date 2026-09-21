///|
struct LightColumn {
  opacity : FixedArray[Byte]
  luminance : FixedArray[Byte]
  sky : FixedArray[Byte]
  seeds : FixedArray[Int]
}

///|
/// Derived optical data and direct sky, updated when terrain changes rather
/// than re-reading the entire world height for every propagation task.
pub struct LightCache {
  size : Int
  min_cy : Int
  max_cy : Int
  columns : @hashmap.HashMap[String, LightColumn]
  lookup : @hashmap.HashMap[UInt, (Byte, Byte)]
}

///|
pub fn LightCache::new(
  size : Int,
  world_min_y : Int,
  world_max_y : Int,
) -> LightCache {
  let lookup : @hashmap.HashMap[UInt, (Byte, Byte)] = @hashmap.HashMap([])
  for entry in @block.collect_block_light_info() {
    lookup[entry[0].reinterpret_as_uint()] = (
      entry[1].to_byte(),
      entry[2].to_byte(),
    )
  }
  {
    size,
    min_cy: @util.floor_div(world_min_y, size),
    max_cy: @util.floor_div(world_max_y, size),
    columns: @hashmap.HashMap([]),
    lookup,
  }
}

///|
fn direct_sky_below(above : Int, opacity : Int) -> Int {
  if opacity >= MAX_LIGHT {
    0
  } else if opacity == 0 && (above == MAX_LIGHT || !ENABLE_SKY_FLOOD_FILL) {
    above
  } else {
    let next = above - opacity - 1
    if next > 0 {
      next
    } else {
      0
    }
  }
}

///|
fn LightCache::refresh_shaft(
  self : LightCache,
  column : LightColumn,
  xz : Int,
) -> Unit {
  let plane = self.size * self.size
  for i = column.sky.length() - plane + xz; i >= 0; i = i - plane {
    let above = if i + plane >= column.sky.length() {
      MAX_LIGHT
    } else {
      column.sky[i + plane].to_int()
    }
    let next = direct_sky_below(above, column.opacity[i].to_int()).to_byte()
    let chunk = i / (plane * self.size)
    if column.sky[i] > 0 {
      column.seeds[chunk] = column.seeds[chunk] - 1
    }
    if next > 0 {
      column.seeds[chunk] = column.seeds[chunk] + 1
    }
    column.sky[i] = next
  }
}

///|
pub fn LightCache::update_column(
  self : LightCache,
  chunks : @hashmap.HashMap[String, Array[UInt]],
  x : Int,
  z : Int,
) -> Unit {
  let cells = self.size * self.size * self.size
  let count = (self.max_cy - self.min_cy + 1) * cells
  let column = LightColumn::{
    opacity: FixedArray::make(count, MAX_LIGHT.to_byte()),
    luminance: FixedArray::make(count, 0),
    sky: FixedArray::make(count, 0),
    seeds: FixedArray::make(self.max_cy - self.min_cy + 1, 0),
  }
  for cy in self.min_cy..<=self.max_cy {
    guard chunks.get(chunk_key_by_chunk_xyz(x, cy, z)) is Some(data) else {
      continue
    }
    for i in 0..<cells {
      guard i < data.length() else { break }
      let (opacity, luminance) = self.lookup.get(data[i]).unwrap_or((15, 0))
      let index = (cy - self.min_cy) * cells + i
      column.opacity[index] = opacity
      column.luminance[index] = luminance
      if luminance > 0 {
        column.seeds[cy - self.min_cy] = column.seeds[cy - self.min_cy] + 1
      }
    }
  }
  for xz in 0..<(self.size * self.size) {
    self.refresh_shaft(column, xz)
  }
  self.columns[chunk_column_key_by_chunk_xz(x, z)] = column
}

///|
/// Return whether opacity changed, requiring a vertical sky invalidation.
pub fn LightCache::update_block(
  self : LightCache,
  wx : Int,
  wy : Int,
  wz : Int,
  id : UInt,
) -> Bool {
  let cx = @util.floor_div(wx, self.size)
  let cz = @util.floor_div(wz, self.size)
  guard self.columns.get(chunk_column_key_by_chunk_xz(cx, cz)) is Some(column) else {
    false
  }
  let xz = (wz - cz * self.size) * self.size + wx - cx * self.size
  let index = (wy - self.min_cy * self.size) * self.size * self.size + xz
  let (opacity, luminance) = self.lookup.get(id).unwrap_or((15, 0))
  let changed = column.opacity[index] != opacity
  column.opacity[index] = opacity
  let chunk = index / (self.size * self.size * self.size)
  if column.luminance[index] > 0 {
    column.seeds[chunk] = column.seeds[chunk] - 1
  }
  if luminance > 0 {
    column.seeds[chunk] = column.seeds[chunk] + 1
  }
  column.luminance[index] = luminance
  if changed {
    self.refresh_shaft(column, xz)
  }
  changed
}

///|
pub fn LightCache::remove_column(self : LightCache, x : Int, z : Int) -> Unit {
  self.columns.remove(chunk_column_key_by_chunk_xz(x, z))
}

///|
/// Fully sky-lit buffers and fully opaque, non-emitting buffers have exact
/// solutions without flooding. Include padding so boundary faces stay correct.
pub fn LightCache::uniform_light(self : LightCache, key : String) -> Bytes? {
  let (cx, cy, cz) = chunk_xyz_by_chunk_key(key)
  let halo = (MAX_LIGHT + self.size - 1) / self.size
  let mut has_source = false
  for x in (cx - halo)..<=(cx + halo) {
    for z in (cz - halo)..<=(cz + halo) {
      guard self.columns.get(chunk_column_key_by_chunk_xz(x, z)) is Some(column) else {
        continue
      }
      for y in (cy - halo)..<=(cy + halo) {
        if y >= self.min_cy &&
          y <= self.max_cy &&
          column.seeds[y - self.min_cy] > 0 {
          has_source = true
        }
      }
    }
  }
  let pad = self.size + 2
  guard has_source else { return Some(Bytes::make(pad * pad * pad, 0)) }
  let plane = self.size * self.size
  let mut dark = true
  let mut bright = true
  for x in -1..<=self.size {
    for z in -1..<=self.size {
      let wx = cx * self.size + x
      let wz = cz * self.size + z
      let nx = @util.floor_div(wx, self.size)
      let nz = @util.floor_div(wz, self.size)
      let column = self.columns.get(chunk_column_key_by_chunk_xz(nx, nz))
      for y in -1..<=self.size {
        let index = (cy * self.size + y - self.min_cy * self.size) * plane +
          (wz - nz * self.size) * self.size +
          wx -
          nx * self.size
        if column is Some(data) && index >= 0 && index < data.sky.length() {
          dark = dark && data.opacity[index] == 15 && data.luminance[index] == 0
          bright = bright && data.sky[index] == 15
        } else {
          bright = false
        }
        guard dark || bright else { return None }
      }
    }
  }
  Some(Bytes::make(pad * pad * pad, if bright { 15 } else { 0 }))
}
