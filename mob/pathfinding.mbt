///|
priv struct PathNode {
  wx : Int
  wy : Int
  wz : Int
}

///|
fn is_solid_floor(long_id : UInt) -> Bool {
  guard long_id != @block.AIR_LONG_ID else { false }
  @block.lookup_by_long_id(long_id)
  .map(fn(block) {
    guard !block.is_water() else { false }
    match block.shape {
      @block.Shape::Air => false
      _ => true
    }
  })
  .unwrap_or(false)
}

///|
fn is_passable(long_id : UInt) -> Bool {
  guard long_id == @block.AIR_LONG_ID else {
    @block.lookup_by_long_id(long_id)
    .map(fn(block) { block.is_water() })
    .unwrap_or(false)
  }
  true
}

///|
fn is_walkable(
  chunk_map : @ffi.JsValue,
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Bool {
  let floor = @level.get_block_id(chunk_map, size, wx, wy - 1, wz)
  let feet = @level.get_block_id(chunk_map, size, wx, wy, wz)
  let head = @level.get_block_id(chunk_map, size, wx, wy + 1, wz)
  floor.map(is_solid_floor).unwrap_or(false) &&
  feet.map(is_passable).unwrap_or(false) &&
  head.map(is_passable).unwrap_or(false)
}

///|
fn pos_key(wx : Int, wy : Int, wz : Int) -> String {
  "\{wx},\{wy},\{wz}"
}
