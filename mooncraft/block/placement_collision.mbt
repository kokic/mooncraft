///|
/// Check placement against an entity body using the block's collision boxes.
/// An empty position means that placement has no entity collision constraint.
pub fn can_place_block(
  internal_id : UInt,
  player_pos : Array[Double],
  entity_height : Double,
  entity_radius : Double,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Bool {
  guard internal_id != @schema.AIR_ID && player_pos.length() >= 3 else {
    true
  }
  guard get_shape_desc(internal_id) is Some(desc) else { false }
  let min_x = player_pos[0] - entity_radius
  let max_x = player_pos[0] + entity_radius
  let min_y = player_pos[1]
  let max_y = player_pos[1] + entity_height
  let min_z = player_pos[2] - entity_radius
  let max_z = player_pos[2] + entity_radius
  for box in desc.boxes {
    let overlaps = max_x > wx.to_double() + box.min[0].to_double() &&
      min_x < wx.to_double() + box.max[0].to_double() &&
      max_y > wy.to_double() + box.min[1].to_double() &&
      min_y < wy.to_double() + box.max[1].to_double() &&
      max_z > wz.to_double() + box.min[2].to_double() &&
      min_z < wz.to_double() + box.max[2].to_double()
    guard !overlaps else { return false }
  }
  true
}
