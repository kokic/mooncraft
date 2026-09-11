///|
priv struct PathNode {
  wx : Int
  wy : Int
  wz : Int
}

///|
fn is_solid_floor(internal_id : UInt) -> Bool {
  guard internal_id != @schema.AIR_ID else { false }
  @block.lookup_by_internal_id(internal_id).map_or(false, fn(block) {
    guard !block.is_water() else { false }
    match block.shape {
      @block.Shape::Air => false
      _ => true
    }
  })
}

///|
fn is_passable(internal_id : UInt) -> Bool {
  guard internal_id == @schema.AIR_ID else {
    @block.lookup_by_internal_id(internal_id).map_or(false, fn(block) {
      block.is_water()
    })
  }
  true
}

///|
fn is_walkable(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Bool {
  let floor = @level.get_block_id(chunk_map, size, wx, wy - 1, wz)
  let feet = @level.get_block_id(chunk_map, size, wx, wy, wz)
  let head = @level.get_block_id(chunk_map, size, wx, wy + 1, wz)
  floor.map_or(false, is_solid_floor) &&
  feet.map_or(false, is_passable) &&
  head.map_or(false, is_passable)
}

///|
fn pos_key(wx : Int, wy : Int, wz : Int) -> String {
  "\{wx},\{wy},\{wz}"
}
