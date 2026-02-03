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
  let cx =  @util.floor_div(wx, size)
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
