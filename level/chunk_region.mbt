///|
pub struct BlockPlacement {
  wx : Int
  wy : Int
  wz : Int
  id : UInt
}

///|
pub struct ChunkRegion {
  chunk : Chunk
}

///|
let pending_block_placements : Map[String, Array[BlockPlacement]] = {}

///|
pub fn ChunkRegion::new(chunk : Chunk) -> ChunkRegion {
  ChunkRegion::{ chunk, }
}

///|
fn enqueue_block(wx : Int, wy : Int, wz : Int, id : UInt) -> Unit {
  let cx = @util.floor_div(wx, CHUNK_X_SIZE)
  let cy = @util.floor_div(wy, CHUNK_Y_SIZE)
  let cz = @util.floor_div(wz, CHUNK_Z_SIZE)
  let key = chunk_key_by_chunk_xyz(cx, cy, cz)
  let placement = BlockPlacement::{ wx, wy, wz, id }
  if pending_block_placements.contains(key) {
    let arr = pending_block_placements[key]
    arr.push(placement)
  } else {
    pending_block_placements[key] = [placement]
  }
}

///|
pub fn ChunkRegion::set_block(
  self : ChunkRegion,
  wx : Int,
  wy : Int,
  wz : Int,
  id : UInt,
) -> Unit {
  let rx = wx - self.chunk.x * CHUNK_X_SIZE
  let ry = wy - self.chunk.y * CHUNK_Y_SIZE
  let rz = wz - self.chunk.z * CHUNK_Z_SIZE
  if Chunk::in_other_chunk(rx, ry, rz) {
    enqueue_block(wx, wy, wz, id)
  } else {
    self.chunk.update_tile_map(rx, ry, rz, id)
  }
}

///|
pub fn apply_pending_to_chunk(chunk : Chunk) -> Unit {
  let key = chunk.chunk_key()
  if pending_block_placements.contains(key) {
    let placements = pending_block_placements[key]
    for placement in placements {
      let rx = placement.wx - chunk.x * CHUNK_X_SIZE
      let ry = placement.wy - chunk.y * CHUNK_Y_SIZE
      let rz = placement.wz - chunk.z * CHUNK_Z_SIZE
      if !Chunk::in_other_chunk(rx, ry, rz) {
        chunk.update_tile_map(rx, ry, rz, placement.id)
      }
    }
    pending_block_placements.remove(key)
  }
}
