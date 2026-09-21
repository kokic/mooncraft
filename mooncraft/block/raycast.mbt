///|
fn ray_intersects_box(
  origin : Array[Double],
  direction : Array[Double],
  wx : Int,
  wy : Int,
  wz : Int,
  box : @shape.Box,
) -> Bool {
  let min = [
    wx.to_double() + box.min[0].to_double(),
    wy.to_double() + box.min[1].to_double(),
    wz.to_double() + box.min[2].to_double(),
  ]
  let max = [
    wx.to_double() + box.max[0].to_double(),
    wy.to_double() + box.max[1].to_double(),
    wz.to_double() + box.max[2].to_double(),
  ]
  let mut has_range = false
  let mut tmin = 0.0
  let mut tmax = 0.0
  for i in 0..<3 {
    let origin_value = origin[i]
    let direction_value = direction[i]
    if direction_value.abs() < 0.00000001 {
      if origin_value < min[i] || origin_value > max[i] {
        return false
      }
    } else {
      let inverse = 1.0 / direction_value
      let t1 = (min[i] - origin_value) * inverse
      let t2 = (max[i] - origin_value) * inverse
      let near = if t1 < t2 { t1 } else { t2 }
      let far = if t1 > t2 { t1 } else { t2 }
      if !has_range {
        tmin = near
        tmax = far
        has_range = true
      } else {
        if near > tmin {
          tmin = near
        }
        if far < tmax {
          tmax = far
        }
        if tmin > tmax {
          return false
        }
      }
    }
  }
  !has_range || tmax >= 0.0
}

///|
/// Test whether a ray can target the block's profile-defined bounds.
pub fn raycast_intersects(
  internal_id : @schema.InternalID,
  origin : Array[Double],
  direction : Array[Double],
  wx : Int,
  wy : Int,
  wz : Int,
  include_liquid : Bool,
) -> Bool {
  guard origin.length() >= 3 && direction.length() >= 3 else { false }
  match lookup_by_internal_id(internal_id) {
    None => false
    Some(block) => {
      let profile = block.profile()
      let can_raycast = match profile.raycast_mode {
        RaycastMode::Skip => false
        RaycastMode::Bounds => true
        RaycastMode::LiquidBounds => include_liquid
      }
      if !can_raycast {
        false
      } else {
        for box in (profile.raycast_boxes)(block.state) {
          if ray_intersects_box(origin, direction, wx, wy, wz, box) {
            return true
          }
        }
        false
      }
    }
  }
}
