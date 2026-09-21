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
/// Returns None if the owning chunk is not loaded.
pub fn get_block_id(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> UInt? {
  let address = BlockAddress::new(size, wx, wy, wz)
  chunk_map.get(address.chunk_key()).map(data => data[address.index(size)])
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
pub fn is_lava_at(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Bool {
  get_block_id(chunk_map, size, wx, wy, wz)
  .bind(id => @block.lookup_by_internal_id(id))
  .map_or(false, block => block.is_lava())
}

///|
pub fn is_cactus_at(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Bool {
  get_block_id(chunk_map, size, wx, wy, wz)
  .bind(id => @block.lookup_by_internal_id(id))
  .map_or(false, block => block.is_cactus())
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
  let address = BlockAddress::new(size, wx, wy, wz)
  let key = address.chunk_key()
  guard chunk_map.get(key) is Some(data) else { [] }
  let index = address.index(size)
  guard data[index] != id else { [] }
  data[index] = id
  @ffi.notify_block_changed(wx, wy, wz, id)
  let keys = [key]
  for (at_boundary, dx, dy, dz) in [
    (address.x == 0, -1, 0, 0),
    (address.x == size - 1, 1, 0, 0),
    (address.y == 0, 0, -1, 0),
    (address.y == size - 1, 0, 1, 0),
    (address.z == 0, 0, 0, -1),
    (address.z == size - 1, 0, 0, 1),
  ] {
    guard at_boundary else { continue }
    let neighbor = chunk_key_by_chunk_xyz(address.cx + dx, address.cy + dy, address.cz + dz)
    if chunk_map.contains(neighbor) {
      keys.push(neighbor)
    }
  }
  keys
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
        if resolve_chunk(key) is Some(chunk) {
          let src_idx = (ly * size + lz) * size + lx
          let out_idx = (py * pad + pz) * pad + px
          out[out_idx] = chunk[src_idx]
        }
      }
    }
  }
  out
}
