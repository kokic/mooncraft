///|
const MAX_LIGHT : Int = 15

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
fn build_light_lookup() -> Map[Int, (Int, Int)] {
  let lookup : Map[Int, (Int, Int)] = Map::new()
  for entry in @block.collect_block_light_info() {
    if entry.length() >= 3 {
      lookup[entry[0]] = (entry[1], entry[2])
    }
  }
  lookup
}

///|
/// Build per-chunk light maps (max of skylight and torchlight) for the
/// specified chunk keys.
pub fn build_world_light(
  chunk_map : @ffi.JsValue,
  size : Int,
  chunk_keys : Array[String],
  _world_min_y : Int,
  _world_max_y : Int,
) -> Array[(String, Bytes)] {
  if chunk_keys.length() == 0 {
    return []
  }
  let lookup = build_light_lookup()
  let coords_all : Array[(String, Int, Int, Int)] = []
  let coords_loaded : Array[(String, Int, Int, Int)] = []
  let chunk_data_by_key : Map[String, Array[UInt]] = Map::new()
  let mut min_cx = 0
  let mut min_cz = 0
  let mut max_cx = 0
  let mut max_cz = 0
  let mut initialized = false
  for key in chunk_keys {
    let (cx, cy, cz) = chunk_xyz_by_chunk_key(key)
    coords_all.push((key, cx, cy, cz))
    if !initialized {
      initialized = true
      min_cx = cx
      min_cz = cz
      max_cx = cx
      max_cz = cz
    } else {
      if cx < min_cx { min_cx = cx }
      if cz < min_cz { min_cz = cz }
      if cx > max_cx { max_cx = cx }
      if cz > max_cz { max_cz = cz }
    }
    match get_chunk_data(chunk_map, key) {
      None => ()
      Some(data) => {
        coords_loaded.push((key, cx, cy, cz))
        chunk_data_by_key[key] = data
      }
    }
  }
  if coords_all.length() == 0 {
    return []
  }
  let min_cy = @util.floor_div(_world_min_y, size)
  let max_cy = @util.floor_div(_world_max_y, size)
  if min_cy > max_cy {
    return []
  }
  for cx in min_cx..=max_cx {
    for cz in min_cz..=max_cz {
      for cy in min_cy..=max_cy {
        let key = chunk_key_by_chunk_xyz(cx, cy, cz)
        if chunk_data_by_key.contains(key) {
          continue
        }
        match get_chunk_data(chunk_map, key) {
          None => ()
          Some(data) => {
            coords_loaded.push((key, cx, cy, cz))
            chunk_data_by_key[key] = data
          }
        }
      }
    }
  }
  if coords_loaded.length() == 0 {
    return []
  }
  let dim_x = (max_cx - min_cx + 1) * size
  let dim_y = (max_cy - min_cy + 1) * size
  let dim_z = (max_cz - min_cz + 1) * size
  if dim_x <= 0 || dim_y <= 0 || dim_z <= 0 {
    return []
  }
  let total = dim_x * dim_y * dim_z
  let opacity : Array[Int] = Array::make(total, 15)
  let luminance : Array[Int] = Array::make(total, 0)
  let index_of = fn(rx : Int, ry : Int, rz : Int) -> Int {
    (ry * dim_z + rz) * dim_x + rx
  }
  for coord in coords_loaded {
    let (key, cx, cy, cz) = coord
    match chunk_data_by_key.get(key) {
      None => ()
      Some(data) => {
        let base_rx = (cx - min_cx) * size
        let base_ry = (cy - min_cy) * size
        let base_rz = (cz - min_cz) * size
        let max_len = size * size * size
        let len = if data.length() < max_len { data.length() } else { max_len }
        for i in 0..<len {
          let (lx, ly, lz) = get_block_rxyz_by_linear_index(i)
          let rx = base_rx + lx
          let ry = base_ry + ly
          let rz = base_rz + lz
          let idx = index_of(rx, ry, rz)
          let key = data[i].reinterpret_as_int()
          match lookup.get(key) {
            Some((op, lum)) => {
              opacity[idx] = op
              luminance[idx] = lum
            }
            None => ()
          }
        }
      }
    }
  }
  let sky : Array[Int] = Array::make(total, 0)
  let torch : Array[Int] = Array::make(total, 0)
  let dirs : Array[(Int, Int, Int)] = [
    (1, 0, 0),
    (-1, 0, 0),
    (0, 1, 0),
    (0, -1, 0),
    (0, 0, 1),
    (0, 0, -1),
  ]

  let sky_qx : Array[Int] = []
  let sky_qy : Array[Int] = []
  let sky_qz : Array[Int] = []
  let sky_push = fn(rx : Int, ry : Int, rz : Int) -> Unit {
    sky_qx.push(rx)
    sky_qy.push(ry)
    sky_qz.push(rz)
  }
  let top_y = dim_y - 1
  for rx in 0..<dim_x {
    for rz in 0..<dim_z {
      let idx = index_of(rx, top_y, rz)
      let block_opacity = opacity[idx]
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
    let idx = index_of(rx, ry, rz)
    let current = sky[idx]
    if current <= 0 {
      continue
    }
    for dir in dirs {
      let (dx, dy, dz) = dir
      let nrx = rx + dx
      let nry = ry + dy
      let nrz = rz + dz
      if nrx < 0 || nrx >= dim_x || nry < 0 || nry >= dim_y || nrz < 0 ||
        nrz >= dim_z {
        continue
      }
      let nidx = index_of(nrx, nry, nrz)
      let block_opacity = opacity[nidx]
      if block_opacity >= 15 {
        continue
      }
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

  let torch_qx : Array[Int] = []
  let torch_qy : Array[Int] = []
  let torch_qz : Array[Int] = []
  let torch_push = fn(rx : Int, ry : Int, rz : Int) -> Unit {
    torch_qx.push(rx)
    torch_qy.push(ry)
    torch_qz.push(rz)
  }
  for ry in 0..<dim_y {
    for rz in 0..<dim_z {
      for rx in 0..<dim_x {
        let idx = index_of(rx, ry, rz)
        let lum = luminance[idx]
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
    let idx = index_of(rx, ry, rz)
    let current = torch[idx]
    if current <= 0 {
      continue
    }
    for dir in dirs {
      let (dx, dy, dz) = dir
      let nrx = rx + dx
      let nry = ry + dy
      let nrz = rz + dz
      if nrx < 0 || nrx >= dim_x || nry < 0 || nry >= dim_y || nrz < 0 ||
        nrz >= dim_z {
        continue
      }
      let nidx = index_of(nrx, nry, nrz)
      let block_opacity = opacity[nidx]
      if block_opacity >= 15 {
        continue
      }
      let next = clamp_light(current - block_opacity - 1)
      if next > torch[nidx] {
        torch[nidx] = next
        if next > 0 {
          torch_push(nrx, nry, nrz)
        }
      }
    }
  }

  let results : Array[(String, Bytes)] = []
  let pad = size + 2
  for coord in coords_loaded {
    let (key, cx, cy, cz) = coord
    let base_rx = (cx - min_cx) * size
    let base_ry = (cy - min_cy) * size
    let base_rz = (cz - min_cz) * size
    let light_bytes = Bytes::makei(pad * pad * pad, fn(i) {
      let px = i % pad
      let py = i / (pad * pad)
      let pz = (i / pad) % pad
      let rx = base_rx + (px - 1)
      let ry = base_ry + (py - 1)
      let rz = base_rz + (pz - 1)
      if rx < 0 || rx >= dim_x || ry < 0 || ry >= dim_y || rz < 0 ||
        rz >= dim_z {
        Int::to_byte(0)
      } else {
        let idx = index_of(rx, ry, rz)
        let sky_val = sky[idx]
        let torch_val = torch[idx]
        let light = if sky_val > torch_val { sky_val } else { torch_val }
        light.to_byte()
      }
    })
    results.push((key, light_bytes))
  }
  results
}
