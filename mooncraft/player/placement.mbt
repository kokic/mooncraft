///|
/// Check if a block placement collides with the player AABB.
pub fn can_place_block(
  internal_id : UInt,
  player_pos : Array[Double],
  entity_height : Double,
  entity_radius : Double,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Bool {
  @block.can_place_block(
    internal_id, player_pos, entity_height, entity_radius, wx, wy, wz,
  )
}
