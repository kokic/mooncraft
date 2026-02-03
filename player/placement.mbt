///|
/// Check if a block placement collides with the player AABB.
pub fn can_place_block(
  long_id : UInt,
  player_pos : Array[Double],
  entity_height : Double,
  entity_radius : Double,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Bool {
  if long_id == @block.AIR_LONG_ID {
    return true
  }
  if player_pos.length() < 3 {
    return true
  }
  match @block.get_shape_desc(long_id) {
    None => false
    Some(desc) => {
      let px = player_pos[0]
      let py = player_pos[1]
      let pz = player_pos[2]
      let ent_min_x = px - entity_radius
      let ent_max_x = px + entity_radius
      let ent_min_y = py
      let ent_max_y = py + entity_height
      let ent_min_z = pz - entity_radius
      let ent_max_z = pz + entity_radius
      for box in desc.boxes {
        let b_min_x = wx.to_double() + box.min[0].to_double()
        let b_max_x = wx.to_double() + box.max[0].to_double()
        let b_min_y = wy.to_double() + box.min[1].to_double()
        let b_max_y = wy.to_double() + box.max[1].to_double()
        let b_min_z = wz.to_double() + box.min[2].to_double()
        let b_max_z = wz.to_double() + box.max[2].to_double()
        if intersects(
            ent_min_x, ent_min_y, ent_min_z, ent_max_x, ent_max_y, ent_max_z, b_min_x,
            b_min_y, b_min_z, b_max_x, b_max_y, b_max_z,
          ) {
          return false
        }
      }
      true
    }
  }
}
