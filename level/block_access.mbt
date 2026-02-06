///|
/// Get chunk data from a JS Map by chunk key.
/// Returns None when the chunk is missing or the value is null/undefined.
pub fn get_chunk_data(chunk_map : @ffi.JsValue, key : String) -> Array[UInt]? {
  let value = @ffi.object_get(chunk_map, key)
  if value.is_undefined() || value.is_null() {
    None
  } else {
    Some(value.cast_to())
  }
}

///|
/// Read the block long_id at world coordinates (wx, wy, wz).
/// Returns None if the chunk is missing or coordinates are out of bounds.
pub fn get_block_id(
  chunk_map : @ffi.JsValue,
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
/// Update the block long_id at world coordinates (wx, wy, wz).
/// Returns the list of chunk keys that need mesh rebuilds (self + neighbors).
pub fn set_block_id(
  chunk_map : @ffi.JsValue,
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
          let keys : Array[String] = [key]
          let push_neighbor = fn(nx : Int, ny : Int, nz : Int) -> Unit {
            let nkey = chunk_key_by_chunk_xyz(nx, ny, nz)
            if @ffi.object_has(chunk_map, nkey) {
              keys.push(nkey)
            }
          }
          if lx == 0 {
            push_neighbor(cx - 1, cy, cz)
          }
          if lx == size - 1 {
            push_neighbor(cx + 1, cy, cz)
          }
          if ly == 0 {
            push_neighbor(cx, cy - 1, cz)
          }
          if ly == size - 1 {
            push_neighbor(cx, cy + 1, cz)
          }
          if lz == 0 {
            push_neighbor(cx, cy, cz - 1)
          }
          if lz == size - 1 {
            push_neighbor(cx, cy, cz + 1)
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
  chunk_map : @ffi.JsValue,
  size : Int,
  cx : Int,
  cy : Int,
  cz : Int,
  air_id : UInt,
) -> Array[UInt] {
  let pad = size + 2
  let out = Array::make(pad * pad * pad, air_id)
  let chunk_cache : Map[String, Array[UInt]] = {}
  let missing_cache : Map[String, Bool] = {}
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
