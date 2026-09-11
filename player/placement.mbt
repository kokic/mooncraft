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
  if internal_id == @schema.AIR_ID {
    return true
  }
  if player_pos.length() < 3 {
    return true
  }
  guard @block.get_shape_desc(internal_id) is Some(desc) else { false }
  let ent_min = [
    player_pos[0] - entity_radius,
    player_pos[1],
    player_pos[2] - entity_radius,
  ]
  let ent_max = [
    player_pos[0] + entity_radius,
    player_pos[1] + entity_height,
    player_pos[2] + entity_radius,
  ]
  for box in desc.boxes {
    let b_min = [
      wx.to_double() + box.min[0].to_double(),
      wy.to_double() + box.min[1].to_double(),
      wz.to_double() + box.min[2].to_double(),
    ]
    let b_max = [
      wx.to_double() + box.max[0].to_double(),
      wy.to_double() + box.max[1].to_double(),
      wz.to_double() + box.max[2].to_double(),
    ]
    guard !aabb_overlap(ent_min, ent_max, b_min, b_max) else { return false }
  }
  true
}
