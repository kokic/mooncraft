///|
const MAX_LIGHT : Int = 15

///|
/// Fixed lighting ignores skylight / torchlight and uses full brightness.
pub const USE_FIXED_LIGHT : Bool = false

///|
/// Let skylight spread into openings and around obstacles.
pub const ENABLE_SKY_FLOOD_FILL : Bool = true

///|
/// Propagate light from emitting blocks.
pub const ENABLE_TORCH_LIGHTING : Bool = true

///|
/// Smooth lighting blends neighboring light values to reduce hard steps.
pub const ENABLE_SMOOTH_LIGHTING : Bool = false

///|
enum LightPhase {
  Copy
  Frontier
  FloodSky
  FloodTorch
  Emit
  Done
}

///|
struct LightSource {
  column : LightColumn
  offset : Int
  base : Int
}

///|
/// A resumable light solve. Runtime batches nearby output columns;
/// the neighboring source columns cover the maximum horizontal light reach.
/// Only completed results are published, so mesh and entity samples agree.
pub struct WorldLightJob {
  size : Int
  dim_x : Int
  dim_y : Int
  dim_z : Int
  sources : Array[LightSource]
  outputs : Array[(String, Int)]
  opacity : FixedArray[Byte]
  sky : FixedArray[Byte]
  torch : FixedArray[Byte]
  sky_queue : Array[Int]
  torch_queue : Array[Int]
  buffer : Array[Byte]
  results : Array[(String, Bytes)]
  mut phase : LightPhase
  mut cursor : Int
}

///|
pub fn LightCache::begin(
  self : LightCache,
  chunk_keys : Array[String],
) -> WorldLightJob {
  let size = self.size
  let mut min_x = 0
  let mut max_x = 0
  let mut min_y = self.max_cy
  let mut max_y = self.min_cy
  let mut min_z = 0
  let mut max_z = 0
  for i, key in chunk_keys {
    let (x, y, z) = chunk_xyz_by_chunk_key(key)
    min_y = if y < min_y { y } else { min_y }
    max_y = if y > max_y { y } else { max_y }
    if i == 0 {
      min_x = x
      max_x = x
      min_z = z
      max_z = z
    } else {
      min_x = if x < min_x { x } else { min_x }
      max_x = if x > max_x { x } else { max_x }
      min_z = if z < min_z { z } else { min_z }
      max_z = if z > max_z { z } else { max_z }
    }
  }
  let halo = (MAX_LIGHT + size - 1) / size
  min_x = min_x - halo
  max_x = max_x + halo
  min_z = min_z - halo
  max_z = max_z + halo
  min_y = (min_y - halo).clamp(min=self.min_cy, max=self.max_cy)
  max_y = (max_y + halo).clamp(min=self.min_cy, max=self.max_cy)
  let dim_x = (max_x - min_x + 1) * size
  let dim_z = (max_z - min_z + 1) * size
  let dim_y = (max_y - min_y + 1) * size
  let base_of = (x : Int, y : Int, z : Int) => {
    (((y - min_y) * dim_z + z - min_z) * dim_x + x - min_x) * size
  }
  let sources : Array[LightSource] = []
  for x in min_x..<=max_x {
    for z in min_z..<=max_z {
      for y in min_y..<=max_y {
        guard self.columns.get(chunk_column_key_by_chunk_xz(x, z))
          is Some(column) else {
          continue
        }
        sources.push({
          column,
          offset: (y - self.min_cy) * size * size * size,
          base: base_of(x, y, z),
        })
      }
    }
  }
  let outputs : Array[(String, Int)] = []
  for key in chunk_keys {
    let (x, y, z) = chunk_xyz_by_chunk_key(key)
    outputs.push((key, base_of(x, y, z)))
  }
  let total = dim_x * dim_y * dim_z
  {
    size,
    dim_x,
    dim_y,
    dim_z,
    sources,
    outputs,
    opacity: FixedArray::make(total, MAX_LIGHT.to_byte()),
    sky: FixedArray::make(total, 0),
    torch: FixedArray::make(total, 0),
    sky_queue: [],
    torch_queue: [],
    buffer: [],
    results: [],
    phase: Copy,
    cursor: 0,
  }
}

///|
fn WorldLightJob::neighbors(
  self : WorldLightJob,
  index : Int,
  visit : (Int, Bool) -> Unit,
) -> Unit {
  let x = index % self.dim_x
  let z = index / self.dim_x % self.dim_z
  let plane = self.dim_x * self.dim_z
  if x > 0 {
    visit(index - 1, false)
  }
  if x + 1 < self.dim_x {
    visit(index + 1, false)
  }
  if z > 0 {
    visit(index - self.dim_x, false)
  }
  if z + 1 < self.dim_z {
    visit(index + self.dim_x, false)
  }
  if index >= plane {
    visit(index - plane, true)
  }
  if index + plane < self.opacity.length() {
    visit(index + plane, false)
  }
}

///|
fn WorldLightJob::spread(
  self : WorldLightJob,
  index : Int,
  skylight : Bool,
) -> Unit {
  let light = if skylight { self.sky } else { self.torch }
  let queue = if skylight { self.sky_queue } else { self.torch_queue }
  let current = light[index].to_int()
  self.neighbors(index, (next_index, down) => {
    let opacity = self.opacity[next_index].to_int()
    guard opacity < MAX_LIGHT else { return }
    let next = if skylight && down && current == MAX_LIGHT && opacity == 0 {
      MAX_LIGHT
    } else {
      current - opacity - 1
    }
    if next > light[next_index].to_int() {
      light[next_index] = next.to_byte()
      queue.push(next_index)
    }
  })
}

///|
fn WorldLightJob::combined(self : WorldLightJob, index : Int) -> Int {
  if self.sky[index].to_int() > self.torch[index].to_int() {
    self.sky[index].to_int()
  } else {
    self.torch[index].to_int()
  }
}

///|
/// Spend at most `budget` voxel/queue operations. No whole-region pass runs
/// outside this budget. Fixed-size typed buffers avoid growing JS number arrays.
pub fn WorldLightJob::advance(self : WorldLightJob, budget : Int) -> Bool {
  let plane = self.dim_x * self.dim_z
  let total = self.opacity.length()
  let cells = self.size * self.size * self.size
  let pad = self.size + 2
  let padded_cells = pad * pad * pad
  let mut remaining = budget
  while remaining > 0 {
    // Flooding visits up to six neighbors per cell, unlike a linear pass.
    let cost = if self.phase is FloodSky || self.phase is FloodTorch {
      6
    } else {
      1
    }
    guard remaining >= cost else { return false }
    remaining = remaining - cost
    match self.phase {
      Copy => {
        let i = self.cursor
        if i >= self.sources.length() * cells {
          self.phase = if ENABLE_SKY_FLOOD_FILL { Frontier } else { FloodTorch }
          self.cursor = 0
          continue
        }
        let source = self.sources[i / cells]
        let offset = i % cells
        let x = offset % self.size
        let z = offset / self.size % self.size
        let y = offset / (self.size * self.size)
        let index = source.base + y * plane + z * self.dim_x + x
        let source_index = source.offset + offset
        self.opacity[index] = source.column.opacity[source_index]
        self.sky[index] = source.column.sky[source_index]
        let luminance = source.column.luminance[source_index]
        if ENABLE_TORCH_LIGHTING && luminance > 0 {
          self.torch[index] = luminance
          self.torch_queue.push(index)
        }
        self.phase = Copy
        self.cursor = i + 1
      }
      Frontier => {
        let i = self.cursor
        if i >= total {
          self.phase = FloodSky
          self.cursor = 0
          continue
        }
        // Direct vertical sky is already solved. Queue only cells that can
        // brighten a neighbor, not every voxel in the open sky.
        let current = self.sky[i].to_int()
        if current > 1 {
          let x = i % self.dim_x
          let z = i / self.dim_x % self.dim_z
          if (
              x > 0 &&
              current - self.opacity[i - 1].to_int() - 1 >
              self.sky[i - 1].to_int()
            ) ||
            (
              x + 1 < self.dim_x &&
              current - self.opacity[i + 1].to_int() - 1 >
              self.sky[i + 1].to_int()
            ) ||
            (
              z > 0 &&
              current - self.opacity[i - self.dim_x].to_int() - 1 >
              self.sky[i - self.dim_x].to_int()
            ) ||
            (
              z + 1 < self.dim_z &&
              current - self.opacity[i + self.dim_x].to_int() - 1 >
              self.sky[i + self.dim_x].to_int()
            ) {
            self.sky_queue.push(i)
          }
        }
        self.phase = Frontier
        self.cursor = i + 1
      }
      FloodSky => {
        let head = self.cursor
        if head >= self.sky_queue.length() {
          self.phase = FloodTorch
          self.cursor = 0
          continue
        }
        self.spread(self.sky_queue[head], true)
        self.phase = FloodSky
        self.cursor = head + 1
      }
      FloodTorch => {
        let head = self.cursor
        if head >= self.torch_queue.length() {
          self.phase = Emit
          self.cursor = 0
          continue
        }
        self.spread(self.torch_queue[head], false)
        self.phase = FloodTorch
        self.cursor = head + 1
      }
      Emit => {
        let i = self.cursor
        if i >= self.outputs.length() * padded_cells {
          self.phase = Done
          return true
        }
        let (key, base) = self.outputs[i / padded_cells]
        let offset = i % padded_cells
        let index = base +
          (offset / (pad * pad) - 1) * plane +
          (offset / pad % pad - 1) * self.dim_x +
          offset % pad -
          1
        let light = if USE_FIXED_LIGHT {
          MAX_LIGHT
        } else if index < 0 || index >= total {
          0
        } else if ENABLE_SMOOTH_LIGHTING {
          let mut sum = self.combined(index)
          let mut count = 1
          self.neighbors(index, (neighbor, _) => {
            sum = sum + self.combined(neighbor)
            count = count + 1
          })
          sum / count
        } else {
          self.combined(index)
        }
        self.buffer.push(light.to_byte())
        if offset + 1 == padded_cells {
          self.results.push((key, Bytes::from_array(self.buffer)))
          self.buffer.clear()
        }
        self.phase = Emit
        self.cursor = i + 1
      }
      Done => return true
    }
  }
  self.phase is Done
}

///|
pub fn WorldLightJob::results(self : WorldLightJob) -> Array[(String, Bytes)] {
  self.results
}

///|
/// Synchronous entry for callers outside the frame loop. Runtime uses advance.
pub fn build_world_light(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  chunk_keys : Array[String],
  world_min_y : Int,
  world_max_y : Int,
) -> Array[(String, Bytes)] {
  guard chunk_keys.length() > 0 else { [] }
  let job = WorldLightJob::new(
    chunk_map, size, chunk_keys, world_min_y, world_max_y,
  )
  while !job.advance(65536) {

  }
  job.results()
}

///|
pub fn WorldLightJob::new(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  chunk_keys : Array[String],
  world_min_y : Int,
  world_max_y : Int,
) -> WorldLightJob {
  let cache = LightCache::new(size, world_min_y, world_max_y)
  let halo = (MAX_LIGHT + size - 1) / size
  for key in chunk_keys {
    let (cx, _, cz) = chunk_xyz_by_chunk_key(key)
    for x in (cx - halo)..<=(cx + halo) {
      for z in (cz - halo)..<=(cz + halo) {
        guard !cache.columns.contains(chunk_column_key_by_chunk_xz(x, z)) else {
          continue
        }
        cache.update_column(chunk_map, x, z)
      }
    }
  }
  cache.begin(chunk_keys)
}
