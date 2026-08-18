///|
/// Get chunk data from the chunk map by chunk key.
/// Returns None when the chunk is missing.
pub fn get_chunk_data(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  key : String,
) -> Array[UInt]? {
  chunk_map.get(key)
}

///|
/// Read the block internal_id at world coordinates (wx, wy, wz).
/// Returns None if the chunk is missing or coordinates are out of bounds.
pub fn get_block_id(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> UInt? {
  let cx = @util.floor_div(wx, size)
  let cy = @util.floor_div(wy, size)
  let cz = @util.floor_div(wz, size)
  let key = chunk_key_by_chunk_xyz(cx, cy, cz)
  match get_chunk_data(chunk_map, key) {
    None => None
    Some(data) => {
      let lx = wx - cx * size
      let ly = wy - cy * size
      let lz = wz - cz * size
      if lx < 0 || lx >= size || ly < 0 || ly >= size || lz < 0 || lz >= size {
        None
      } else {
        let idx = (ly * size + lz) * size + lx
        Some(data[idx])
      }
    }
  }
}

///|
pub fn is_water_at(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Bool {
  get_block_id(chunk_map, size, wx, wy, wz)
  .bind(id => @block.lookup_by_internal_id(id))
  .map_or(false, block => block.is_water())
}

///|
/// Update the block internal_id at world coordinates (wx, wy, wz).
/// Returns the list of chunk keys that need mesh rebuilds (self + neighbors).
pub fn set_block_id(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
  id : UInt,
) -> Array[String] {
  let cx = @util.floor_div(wx, size)
  let cy = @util.floor_div(wy, size)
  let cz = @util.floor_div(wz, size)
  let key = chunk_key_by_chunk_xyz(cx, cy, cz)
  match get_chunk_data(chunk_map, key) {
    None => []
    Some(data) => {
      let lx = wx - cx * size
      let ly = wy - cy * size
      let lz = wz - cz * size
      if lx < 0 || lx >= size || ly < 0 || ly >= size || lz < 0 || lz >= size {
        []
      } else {
        let idx = (ly * size + lz) * size + lx
        if data[idx] == id {
          []
        } else {
          data[idx] = id
          @ffi.notify_block_changed(wx, wy, wz, id)
          let keys : Array[String] = [key]
          let push_neighbor = fn(nx : Int, ny : Int, nz : Int) -> Unit {
            let nkey = chunk_key_by_chunk_xyz(nx, ny, nz)
            if chunk_map.contains(nkey) {
              keys.push(nkey)
            }
          }
          match () {
            _ if lx == 0 => push_neighbor(cx - 1, cy, cz)
            _ if lx == size - 1 => push_neighbor(cx + 1, cy, cz)
            _ if ly == 0 => push_neighbor(cx, cy - 1, cz)
            _ if ly == size - 1 => push_neighbor(cx, cy + 1, cz)
            _ if lz == 0 => push_neighbor(cx, cy, cz - 1)
            _ if lz == size - 1 => push_neighbor(cx, cy, cz + 1)
            _ => ()
          }
          keys
        }
      }
    }
  }
}

///|
/// Build padded block data for one chunk (size+2)^3.
/// Border voxels are sampled from neighbor chunks; missing chunks use `air_id`.
pub fn build_chunk_data_padded(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  cx : Int,
  cy : Int,
  cz : Int,
  air_id : UInt,
) -> Array[UInt] {
  let pad = size + 2
  let out = Array::make(pad * pad * pad, air_id)
  let chunk_cache : @hashmap.HashMap[String, Array[UInt]] = @hashmap.HashMap([])
  let missing_cache : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  let resolve_chunk = fn(key : String) -> Array[UInt]? {
    if chunk_cache.contains(key) {
      Some(chunk_cache[key])
    } else if missing_cache.contains(key) {
      None
    } else {
      match get_chunk_data(chunk_map, key) {
        Some(data) => {
          chunk_cache[key] = data
          Some(data)
        }
        None => {
          missing_cache[key] = true
          None
        }
      }
    }
  }
  let base_x = cx * size
  let base_y = cy * size
  let base_z = cz * size
  for py in 0..<pad {
    let wy = base_y + py - 1
    let ncy = @util.floor_div(wy, size)
    let ly = wy - ncy * size
    for pz in 0..<pad {
      let wz = base_z + pz - 1
      let ncz = @util.floor_div(wz, size)
      let lz = wz - ncz * size
      for px in 0..<pad {
        let wx = base_x + px - 1
        let ncx = @util.floor_div(wx, size)
        let lx = wx - ncx * size
        let key = chunk_key_by_chunk_xyz(ncx, ncy, ncz)
        match resolve_chunk(key) {
          Some(chunk) => {
            let src_idx = (ly * size + lz) * size + lx
            let out_idx = (py * pad + pz) * pad + px
            out[out_idx] = chunk[src_idx]
          }
          None => ()
        }
      }
    }
  }
  out
}
