///|
const MAX_LIGHT : Int = 15

///|
/// Fixed lighting ignores skylight / torchlight and uses full brightness.
pub const USE_FIXED_LIGHT : Bool = true

///|
/// Keep only vertical skylight blocking (cheap and stable).
pub const ENABLE_SKY_FLOOD_FILL : Bool = true

///|
/// Torch flood fill is visually subtle but expensive.
pub const ENABLE_TORCH_LIGHTING : Bool = true

///|
/// Smooth lighting blends neighboring light values to reduce hard steps.
pub const ENABLE_SMOOTH_LIGHTING : Bool = false

///|
let light_dirs : Array[(Int, Int, Int)] = [
  (1, 0, 0),
  (-1, 0, 0),
  (0, 1, 0),
  (0, -1, 0),
  (0, 0, 1),
  (0, 0, -1),
]

///|
fn clamp_light(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > MAX_LIGHT {
    MAX_LIGHT
  } else {
    value
  }
}

///|
fn build_light_lookup() -> @hashmap.HashMap[Int, (Int, Int)] {
  let lookup : @hashmap.HashMap[Int, (Int, Int)] = @hashmap.HashMap([])
  for entry in @block.collect_block_light_info() {
    if entry.length() >= 3 {
      lookup[entry[0]] = (entry[1], entry[2])
    }
  }
  lookup
}

///|
/// The loaded chunks that contribute light, plus the world-space bounds of
/// the light region they span.
priv struct LightCoords {
  loaded : Array[(String, Int, Int, Int)]
  min_cx : Int
  max_cx : Int
  min_cz : Int
  max_cz : Int
  min_cy : Int
  max_cy : Int
}

///|
/// Per-block opacity, luminance, and presence over the whole light region.
priv struct LightGrid {
  dim_x : Int
  dim_y : Int
  dim_z : Int
  opacity : Array[Int]
  luminance : Array[Int]
  loaded : Array[Bool]
}

///|
fn LightGrid::index_of(self : LightGrid, rx : Int, ry : Int, rz : Int) -> Int {
  (ry * self.dim_z + rz) * self.dim_x + rx
}

///|
/// Build per-chunk light maps (max of skylight and torchlight) for the
/// specified chunk keys.
pub fn build_world_light(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  chunk_keys : Array[String],
  world_min_y : Int,
  world_max_y : Int,
) -> Array[(String, Bytes)] {
  if chunk_keys.length() == 0 {
    return []
  }
  if USE_FIXED_LIGHT {
    return fixed_light_results(chunk_keys, size)
  }
  let coords = collect_light_coords(
    chunk_map, size, chunk_keys, world_min_y, world_max_y,
  )
  guard coords.loaded.length() > 0 else { [] }
  let grid = build_light_grid(chunk_map, coords, size)
  let sky = compute_sky_light(grid)
  let torch = compute_torch_light(grid)
  let light = combine_light(sky, torch)
  let light_out = if ENABLE_SMOOTH_LIGHTING {
    smooth_light(grid, light)
  } else {
    light
  }
  emit_chunk_light(coords, grid, light_out, size)
}

///|
fn fixed_light_results(
  chunk_keys : Array[String],
  size : Int,
) -> Array[(String, Bytes)] {
  let pad = size + 2
  let light_bytes = Bytes::makei(pad * pad * pad, _ => Int::to_byte(MAX_LIGHT))
  chunk_keys.map(key => (key, light_bytes))
}

///|
/// Collect the loaded chunk coordinates for the requested keys, then fill in
/// the neighbor columns of the bounding rectangle.
fn collect_light_coords(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  chunk_keys : Array[String],
  world_min_y : Int,
  world_max_y : Int,
) -> LightCoords {
  let loaded : Array[(String, Int, Int, Int)] = []
  let chunk_data_by_key : @hashmap.HashMap[String, Array[UInt]] = @hashmap.HashMap([],
  )
  let mut min_cx = 0
  let mut min_cz = 0
  let mut max_cx = 0
  let mut max_cz = 0
  let mut initialized = false
  for key in chunk_keys {
    let (cx, cy, cz) = chunk_xyz_by_chunk_key(key)
    if !initialized {
      initialized = true
      min_cx = cx
      min_cz = cz
      max_cx = cx
      max_cz = cz
    } else {
      if cx < min_cx {
        min_cx = cx
      }
      if cz < min_cz {
        min_cz = cz
      }
      if cx > max_cx {
        max_cx = cx
      }
      if cz > max_cz {
        max_cz = cz
      }
    }
    guard get_chunk_data(chunk_map, key) is Some(data) else { continue }
    loaded.push((key, cx, cy, cz))
    chunk_data_by_key[key] = data
  }
  let min_cy = @util.floor_div(world_min_y, size)
  let max_cy = @util.floor_div(world_max_y, size)
  if min_cy <= max_cy {
    for cx in min_cx..<=max_cx {
      for cz in min_cz..<=max_cz {
        for cy in min_cy..<=max_cy {
          let key = chunk_key_by_chunk_xyz(cx, cy, cz)
          if chunk_data_by_key.contains(key) {
            continue
          }
          guard get_chunk_data(chunk_map, key) is Some(data) else { continue }
          loaded.push((key, cx, cy, cz))
          chunk_data_by_key[key] = data
        }
      }
    }
  }
  { loaded, min_cx, max_cx, min_cz, max_cz, min_cy, max_cy }
}

///|
/// Copy each loaded chunk's block opacity and luminance into the region grid.
fn build_light_grid(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  coords : LightCoords,
  size : Int,
) -> LightGrid {
  let dim_x = (coords.max_cx - coords.min_cx + 1) * size
  let dim_y = (coords.max_cy - coords.min_cy + 1) * size
  let dim_z = (coords.max_cz - coords.min_cz + 1) * size
  let total = dim_x * dim_y * dim_z
  let grid = LightGrid::{
    dim_x,
    dim_y,
    dim_z,
    opacity: Array::make(total, 15),
    luminance: Array::make(total, 0),
    loaded: Array::make(total, false),
  }
  let lookup = build_light_lookup()
  for coord in coords.loaded {
    let (key, cx, cy, cz) = coord
    guard get_chunk_data(chunk_map, key) is Some(data) else { continue }
    let base_rx = (cx - coords.min_cx) * size
    let base_ry = (cy - coords.min_cy) * size
    let base_rz = (cz - coords.min_cz) * size
    let max_len = size * size * size
    let len = if data.length() < max_len { data.length() } else { max_len }
    for i in 0..<len {
      let (lx, ly, lz) = get_block_rxyz_by_linear_index(i)
      let idx = grid.index_of(base_rx + lx, base_ry + ly, base_rz + lz)
      let key = data[i].reinterpret_as_int()
      guard lookup.get(key) is Some((op, lum)) else { continue }
      grid.opacity[idx] = op
      grid.luminance[idx] = lum
      grid.loaded[idx] = true
    }
  }
  grid
}

///|
/// Skylight: flood from the top when `ENABLE_SKY_FLOOD_FILL`, otherwise a
/// single vertical pass.
fn compute_sky_light(grid : LightGrid) -> Array[Int] {
  if ENABLE_SKY_FLOOD_FILL {
    flood_sky_light(grid)
  } else {
    vertical_sky_light(grid)
  }
}

///|
fn flood_sky_light(grid : LightGrid) -> Array[Int] {
  let sky : Array[Int] = Array::make(grid.dim_x * grid.dim_y * grid.dim_z, 0)
  let sky_qx : Array[Int] = []
  let sky_qy : Array[Int] = []
  let sky_qz : Array[Int] = []
  let sky_push = fn(rx : Int, ry : Int, rz : Int) -> Unit {
    sky_qx.push(rx)
    sky_qy.push(ry)
    sky_qz.push(rz)
  }
  let top_y = grid.dim_y - 1
  for rx in 0..<grid.dim_x {
    for rz in 0..<grid.dim_z {
      let idx = grid.index_of(rx, top_y, rz)
      let block_opacity = if grid.loaded[idx] { grid.opacity[idx] } else { 15 }
      if block_opacity >= 15 {
        continue
      }
      let light = if block_opacity == 0 {
        15
      } else {
        clamp_light(15 - block_opacity - 1)
      }
      sky[idx] = light
      if light > 0 {
        sky_push(rx, top_y, rz)
      }
    }
  }
  let mut sky_head = 0
  while sky_head < sky_qx.length() {
    let rx = sky_qx[sky_head]
    let ry = sky_qy[sky_head]
    let rz = sky_qz[sky_head]
    sky_head = sky_head + 1
    let idx = grid.index_of(rx, ry, rz)
    let current = sky[idx]
    if current <= 0 {
      continue
    }
    for dir in light_dirs {
      let (dx, dy, dz) = dir
      let nrx = rx + dx
      let nry = ry + dy
      let nrz = rz + dz
      guard in_bounds(grid, nrx, nry, nrz) else { continue }
      let nidx = grid.index_of(nrx, nry, nrz)
      guard grid.loaded[nidx] else { continue }
      let block_opacity = grid.opacity[nidx]
      guard block_opacity < 15 else { continue }
      let next = if current == 15 && dy == -1 && block_opacity == 0 {
        15
      } else {
        clamp_light(current - block_opacity - 1)
      }
      if next > sky[nidx] {
        sky[nidx] = next
        if next > 0 {
          sky_push(nrx, nry, nrz)
        }
      }
    }
  }
  sky
}

///|
/// Fast path: vertical skylight only (full block opacity casts obvious shadows).
fn vertical_sky_light(grid : LightGrid) -> Array[Int] {
  let sky : Array[Int] = Array::make(grid.dim_x * grid.dim_y * grid.dim_z, 0)
  for rx in 0..<grid.dim_x {
    for rz in 0..<grid.dim_z {
      let mut current = 15
      let mut ry = grid.dim_y - 1
      while ry >= 0 {
        let idx = grid.index_of(rx, ry, rz)
        if !grid.loaded[idx] {
          current = 0
          sky[idx] = 0
          ry = ry - 1
          continue
        }
        let block_opacity = grid.opacity[idx]
        if block_opacity >= 15 {
          current = 0
          sky[idx] = 0
        } else {
          if block_opacity > 0 {
            current = clamp_light(current - block_opacity - 1)
          }
          sky[idx] = current
        }
        ry = ry - 1
      }
    }
  }
  sky
}

///|
/// Torchlight: flood from every emitting block.
fn compute_torch_light(grid : LightGrid) -> Array[Int] {
  if !ENABLE_TORCH_LIGHTING {
    return Array::make(grid.dim_x * grid.dim_y * grid.dim_z, 0)
  }
  let torch : Array[Int] = Array::make(grid.dim_x * grid.dim_y * grid.dim_z, 0)
  let torch_qx : Array[Int] = []
  let torch_qy : Array[Int] = []
  let torch_qz : Array[Int] = []
  let torch_push = fn(rx : Int, ry : Int, rz : Int) -> Unit {
    torch_qx.push(rx)
    torch_qy.push(ry)
    torch_qz.push(rz)
  }
  for ry in 0..<grid.dim_y {
    for rz in 0..<grid.dim_z {
      for rx in 0..<grid.dim_x {
        let idx = grid.index_of(rx, ry, rz)
        let lum = grid.luminance[idx]
        if lum > 0 {
          let light = clamp_light(lum)
          torch[idx] = light
          torch_push(rx, ry, rz)
        }
      }
    }
  }
  let mut torch_head = 0
  while torch_head < torch_qx.length() {
    let rx = torch_qx[torch_head]
    let ry = torch_qy[torch_head]
    let rz = torch_qz[torch_head]
    torch_head = torch_head + 1
    let idx = grid.index_of(rx, ry, rz)
    let current = torch[idx]
    if current <= 0 {
      continue
    }
    for dir in light_dirs {
      let (dx, dy, dz) = dir
      let nrx = rx + dx
      let nry = ry + dy
      let nrz = rz + dz
      guard in_bounds(grid, nrx, nry, nrz) else { continue }
      let nidx = grid.index_of(nrx, nry, nrz)
      let block_opacity = grid.opacity[nidx]
      guard block_opacity < 15 else { continue }
      let next = clamp_light(current - block_opacity - 1)
      if next > torch[nidx] {
        torch[nidx] = next
        if next > 0 {
          torch_push(nrx, nry, nrz)
        }
      }
    }
  }
  torch
}

///|
fn in_bounds(grid : LightGrid, rx : Int, ry : Int, rz : Int) -> Bool {
  rx >= 0 &&
  rx < grid.dim_x &&
  ry >= 0 &&
  ry < grid.dim_y &&
  rz >= 0 &&
  rz < grid.dim_z
}

///|
fn combine_light(sky : Array[Int], torch : Array[Int]) -> Array[Int] {
  let light = Array::make(sky.length(), 0)
  for i in 0..<sky.length() {
    let sky_val = sky[i]
    let torch_val = torch[i]
    light[i] = if sky_val > torch_val { sky_val } else { torch_val }
  }
  light
}

///|
/// Blend each cell with its in-bounds neighbors.
fn smooth_light(grid : LightGrid, light : Array[Int]) -> Array[Int] {
  let smoothed : Array[Int] = Array::make(
    grid.dim_x * grid.dim_y * grid.dim_z,
    0,
  )
  for rx in 0..<grid.dim_x {
    for ry in 0..<grid.dim_y {
      for rz in 0..<grid.dim_z {
        let idx = grid.index_of(rx, ry, rz)
        let mut sum = light[idx]
        let mut count = 1
        for dir in light_dirs {
          let (dx, dy, dz) = dir
          let nrx = rx + dx
          let nry = ry + dy
          let nrz = rz + dz
          guard in_bounds(grid, nrx, nry, nrz) else { continue }
          let nidx = grid.index_of(nrx, nry, nrz)
          sum = sum + light[nidx]
          count = count + 1
        }
        smoothed[idx] = sum / count
      }
    }
  }
  smoothed
}

///|
/// Emit each loaded chunk's light as a padded (size+2)^3 byte map.
fn emit_chunk_light(
  coords : LightCoords,
  grid : LightGrid,
  light_out : Array[Int],
  size : Int,
) -> Array[(String, Bytes)] {
  let pad = size + 2
  let results : Array[(String, Bytes)] = []
  for coord in coords.loaded {
    let (key, cx, cy, cz) = coord
    let base_rx = (cx - coords.min_cx) * size
    let base_ry = (cy - coords.min_cy) * size
    let base_rz = (cz - coords.min_cz) * size
    let light_bytes = Bytes::makei(pad * pad * pad, fn(i) {
      let px = i % pad
      let py = i / (pad * pad)
      let pz = i / pad % pad
      let rx = base_rx + (px - 1)
      let ry = base_ry + (py - 1)
      let rz = base_rz + (pz - 1)
      if rx < 0 ||
        rx >= grid.dim_x ||
        ry < 0 ||
        ry >= grid.dim_y ||
        rz < 0 ||
        rz >= grid.dim_z {
        Int::to_byte(0)
      } else {
        let idx = grid.index_of(rx, ry, rz)
        light_out[idx].to_byte()
      }
    })
    results.push((key, light_bytes))
  }
  results
}
