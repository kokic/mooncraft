///|
pub struct SpawnResult {
  position : Array[Double]
  surface_y : Int
}

///|
pub struct RaycastResult {
  block : Array[Int]
  prev : @ffi.JsValue
}

///|
fn ray_intersects_aabb(
  origin : Array[Double],
  dir : Array[Double],
  min : Array[Double],
  max : Array[Double],
) -> Bool {
  let mut has_range = false
  let mut tmin = 0.0
  let mut tmax = 0.0
  for i in 0..<3 {
    let o = origin[i]
    let d = dir[i]
    let min_v = min[i]
    let max_v = max[i]
    if d.abs() < 0.00000001 {
      if o < min_v || o > max_v {
        return false
      }
    } else {
      let inv = 1.0 / d
      let t1 = (min_v - o) * inv
      let t2 = (max_v - o) * inv
      let t_near = if t1 < t2 { t1 } else { t2 }
      let t_far = if t1 > t2 { t1 } else { t2 }
      if !has_range {
        tmin = t_near
        tmax = t_far
        has_range = true
      } else {
        if t_near > tmin {
          tmin = t_near
        }
        if t_far < tmax {
          tmax = t_far
        }
        if tmin > tmax {
          return false
        }
      }
    }
  }
  if !has_range {
    true
  } else {
    tmax >= 0.0
  }
}

///|
fn torch_bounds_by_state(state : UInt) -> (Array[Float], Array[Float]) {
  let bounds = @genus.Torch::collect_bounds()
  let idx = match state.reinterpret_as_int() {
    1 => 2 // north
    2 => 4 // south
    3 => 6 // west
    4 => 8 // east
    _ => 0 // floor
  }
  (bounds[idx], bounds[idx + 1])
}

///|
///|
fn get_block_at(
  chunk_map : @ffi.JsValue,
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> UInt? {
  get_block_id(chunk_map, size, wx, wy, wz)
}

///|
fn find_surface_y(
  chunk_map : @ffi.JsValue,
  size : Int,
  chunk_min_y : Int,
  chunk_max_y : Int,
  chunk_x : Int,
  chunk_z : Int,
  local_x : Int,
  local_z : Int,
  air_id : UInt,
) -> Int? {
  for cy = chunk_max_y; cy >= chunk_min_y; {
    let key = chunk_key_by_chunk_xyz(chunk_x, cy, chunk_z)
    match get_chunk_data(chunk_map, key) {
      None => continue cy - 1
      Some(data) =>
        for y = size - 1; y >= 0; {
          let idx = (y * size + local_z) * size + local_x
          if data[idx] != air_id {
            return Some(cy * size + y)
          }
          continue y - 1
        } else {
          continue cy - 1
        }
    }
  } else {
    None
  }
}

///|
pub fn compute_spawn_position(
  chunk_map : @ffi.JsValue,
  size : Int,
  chunk_min_y : Int,
  chunk_max_y : Int,
  chunk_x : Int,
  chunk_z : Int,
  local_x : Int,
  local_z : Int,
  surface_offset : Int,
  fallback_y : Int,
  air_id : UInt,
) -> SpawnResult {
  let surface_y = find_surface_y(
    chunk_map, size, chunk_min_y, chunk_max_y, chunk_x, chunk_z, local_x, local_z,
    air_id,
  )
  let base_y = match surface_y {
    Some(v) => v
    None => fallback_y
  }
  let spawn_y = base_y + surface_offset
  let px = local_x.to_double() + 0.5
  let py = spawn_y.to_double()
  let pz = local_z.to_double() + 0.5
  let surface_out = match surface_y {
    Some(v) => v
    None => -1
  }
  SpawnResult::{ position: [px, py, pz], surface_y: surface_out }
}

///|
pub fn raycast_blocks(
  chunk_map : @ffi.JsValue,
  size : Int,
  origin : Array[Double],
  dir : Array[Double],
  max_dist : Double,
  step : Double,
  air_id : UInt,
) -> RaycastResult? {
  if origin.length() < 3 || dir.length() < 3 {
    None
  } else {
    let mut t = 0.0
    let mut last_pos : (Int, Int, Int)? = None
    while t <= max_dist {
      let px = origin[0] + dir[0] * t
      let py = origin[1] + dir[1] * t
      let pz = origin[2] + dir[2] * t
      let bx = px.floor().to_int()
      let by = py.floor().to_int()
      let bz = pz.floor().to_int()
      let changed = match last_pos {
        None => true
        Some((lx, ly, lz)) => bx != lx || by != ly || bz != lz
      }
      if changed {
        let hit = get_block_at(chunk_map, size, bx, by, bz)
        match hit {
          Some(id) if id != air_id => {
            let mut allow_hit = true
            match @block.lookup_by_long_id(id) {
              Some(block) =>
                match block.shape {
                  @block.Shape::Torch
                  | @block.Shape::RedstoneTorch
                  | @block.Shape::RedstoneTorchClassic => {
                    let (bmin_f, bmax_f) = torch_bounds_by_state(block.state)
                    let min = [
                      bx.to_double() + bmin_f[0].to_double(),
                      by.to_double() + bmin_f[1].to_double(),
                      bz.to_double() + bmin_f[2].to_double(),
                    ]
                    let max = [
                      bx.to_double() + bmax_f[0].to_double(),
                      by.to_double() + bmax_f[1].to_double(),
                      bz.to_double() + bmax_f[2].to_double(),
                    ]
                    allow_hit = ray_intersects_aabb(origin, dir, min, max)
                  }
                  _ => ()
                }
              None => ()
            }
            if allow_hit {
              let prev = match last_pos {
                Some((lx, ly, lz)) => @ffi.JsValue::cast_from([lx, ly, lz])
                None => @ffi.JsValue::null()
              }
              return Some(RaycastResult::{ block: [bx, by, bz], prev })
            } else {
              last_pos = Some((bx, by, bz))
            }
          }
          _ => last_pos = Some((bx, by, bz))
        }
      }
      t = t + step
    }
    None
  }
}
