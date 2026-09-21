///|
/// World and actor context shared by every action in an interaction batch.
priv struct BlockInteraction {
  chunk_map : @hashmap.HashMap[String, Array[UInt]]
  size : Int
  player_pos : Array[Double]
  entity_height : Double
  entity_radius : Double
}

///|
fn BlockInteraction::new(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  player_pos? : Array[Double] = [],
  entity_height? : Double = 0,
  entity_radius? : Double = 0,
) -> BlockInteraction {
  { chunk_map, size, player_pos, entity_height, entity_radius, }
}

///|
fn BlockInteraction::block_at(
  self : BlockInteraction,
  wx : Int,
  wy : Int,
  wz : Int,
) -> UInt? {
  get_block_id(self.chunk_map, self.size, wx, wy, wz)
}

///|
fn BlockInteraction::set_block(
  self : BlockInteraction,
  wx : Int,
  wy : Int,
  wz : Int,
  id : UInt,
) -> Array[String] {
  set_block_id(self.chunk_map, self.size, wx, wy, wz, id)
}

///|
fn BlockInteraction::is_air_at(
  self : BlockInteraction,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Bool {
  self.block_at(wx, wy, wz).map_or(false, id => id == @schema.AIR_ID)
}

///|
fn BlockInteraction::can_replace_at(
  self : BlockInteraction,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Bool {
  self.block_at(wx, wy, wz).map_or(false, id => {
    id == @schema.AIR_ID ||
    @block.lookup_by_internal_id(id).map_or(false, block => {
      block.shape is @block.Shape::Liquid
    })
  })
}
