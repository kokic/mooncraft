///|
pub(all) struct SpawnResult {
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
pub fn find_surface_y(
  chunk_map : @ffi.JsValue,
  size : Int,
  chunk_min_y : Int,
  chunk_max_y : Int,
  chunk_x : Int,
  chunk_z : Int,
  local_x : Int,
  local_z : Int,
) -> Int? {
  for cy = chunk_max_y; cy >= chunk_min_y; {
    let key = chunk_key_by_chunk_xyz(chunk_x, cy, chunk_z)
    match get_chunk_data(chunk_map, key) {
      None => continue cy - 1
      Some(data) =>
        for y = size - 1; y >= 0; {
          let idx = (y * size + local_z) * size + local_x
          if data[idx] != @block.AIR_LONG_ID {
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
pub fn raycast_blocks(
  chunk_map : @ffi.JsValue,
  size : Int,
  origin : Array[Double],
  dir : Array[Double],
  max_dist : Double,
  _step : Double,
  air_id : UInt,
) -> RaycastResult? {
  if origin.length() < 3 || dir.length() < 3 {
    None
  } else {
    let dx = dir[0]
    let dy = dir[1]
    let dz = dir[2]
    let eps = 0.00000001
    if dx.abs() < eps && dy.abs() < eps && dz.abs() < eps {
      return None
    }
    let mut bx = origin[0].floor().to_int()
    let mut by = origin[1].floor().to_int()
    let mut bz = origin[2].floor().to_int()
    let sx = if dx > 0.0 { 1 } else if dx < 0.0 { -1 } else { 0 }
    let sy = if dy > 0.0 { 1 } else if dy < 0.0 { -1 } else { 0 }
    let sz = if dz > 0.0 { 1 } else if dz < 0.0 { -1 } else { 0 }
    let inf = max_dist + 1.0
    let mut t_max_x = if sx == 0 {
      inf
    } else if sx > 0 {
      (bx.to_double() + 1.0 - origin[0]) / dx
    } else {
      (origin[0] - bx.to_double()) / -dx
    }
    let mut t_max_y = if sy == 0 {
      inf
    } else if sy > 0 {
      (by.to_double() + 1.0 - origin[1]) / dy
    } else {
      (origin[1] - by.to_double()) / -dy
    }
    let mut t_max_z = if sz == 0 {
      inf
    } else if sz > 0 {
      (bz.to_double() + 1.0 - origin[2]) / dz
    } else {
      (origin[2] - bz.to_double()) / -dz
    }
    let t_delta_x = if sx == 0 { inf } else { 1.0 / dx.abs() }
    let t_delta_y = if sy == 0 { inf } else { 1.0 / dy.abs() }
    let t_delta_z = if sz == 0 { inf } else { 1.0 / dz.abs() }
    let mut traveled = 0.0
    let mut last_pos : (Int, Int, Int)? = None
    while traveled <= max_dist {
      let hit = get_block_at(chunk_map, size, bx, by, bz)
      match hit {
        Some(id) if id != air_id => {
          let mut allow_hit = true
          match @block.lookup_by_long_id(id) {
            Some(block) =>
              match block.shape {
                @block.Shape::Liquid =>
                  // Treat liquids as pass-through for selection/raycast.
                  allow_hit = false
                shape if shape.is_torch_genus() => {
                  let box = @genus.Torch::shape_box_by_state(block.state)
                  let bmin_f = box.min
                  let bmax_f = box.max
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
      if t_max_x <= t_max_y && t_max_x <= t_max_z {
        bx = bx + sx
        traveled = t_max_x
        t_max_x = t_max_x + t_delta_x
      } else if t_max_y <= t_max_z {
        by = by + sy
        traveled = t_max_y
        t_max_y = t_max_y + t_delta_y
      } else {
        bz = bz + sz
        traveled = t_max_z
        t_max_z = t_max_z + t_delta_z
      }
    }
    None
  }
}
