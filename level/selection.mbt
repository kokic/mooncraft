///|
pub(all) struct SpawnResult {
  position : Array[Double]
  surface_y : Int
}

///|
pub struct RaycastResult {
  block : Array[Int]
  prev : @ffi.JsValue
  click : (Float, Float, Float)
}

///|

///|
fn get_block_at(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> UInt? {
  get_block_id(chunk_map, size, wx, wy, wz)
}

///|
fn clamp_click_offset(v : Double) -> Float {
  if v <= 0.0 {
    0.0
  } else if v >= 1.0 {
    1.0
  } else {
    Float::from_double(v)
  }
}

///|
pub fn find_surface_y(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
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
    guard get_chunk_data(chunk_map, key) is Some(data) else { continue cy - 1 }
    for y = size - 1; y >= 0; {
      let idx = (y * size + local_z) * size + local_x
      if data[idx] != @schema.AIR_ID {
        return Some(cy * size + y)
      }
      continue y - 1
    } nobreak {
      continue cy - 1
    }
  } nobreak {
    None
  }
}

///|
pub fn raycast_blocks(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  origin : Array[Double],
  dir : Array[Double],
  max_dist : Double,
  // _step : Double,
  air_id : UInt,
  include_liquid_hit : Bool,
) -> RaycastResult? {
  guard origin.length() >= 3 && dir.length() >= 3 else { None }
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
        let allow_hit = @block.raycast_intersects(
          id, origin, dir, bx, by, bz, include_liquid_hit,
        )
        if allow_hit {
          let prev = match last_pos {
            Some((lx, ly, lz)) => @ffi.JsValue::cast_from([lx, ly, lz])
            None => @ffi.JsValue::null()
          }
          let hit_x = origin[0] + dx * traveled
          let hit_y = origin[1] + dy * traveled
          let hit_z = origin[2] + dz * traveled
          let click = (
            clamp_click_offset(hit_x - bx.to_double()),
            clamp_click_offset(hit_y - by.to_double()),
            clamp_click_offset(hit_z - bz.to_double()),
          )
          return Some(RaycastResult::{ block: [bx, by, bz], prev, click })
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
