///|
/// Collision queries share the same world and body dimensions for a move.
priv struct PlayerCollider {
  chunk_map : @hashmap.HashMap[String, Array[UInt]]
  size : Int
  entity_height : Double
  entity_radius : Double
}

///|
/// Ground contact tolerance in blocks.
const GROUND_PROBE_TOLERANCE : Double = 0.05

///|
/// Whether a solid face sits directly below the player's feet.
fn PlayerCollider::is_on_ground(
  self : PlayerCollider,
  pos : Array[Double],
) -> Bool {
  let foot_y = pos[1]
  let block_y = (foot_y - GROUND_PROBE_TOLERANCE).floor().to_int()
  let min_x = (pos[0] - self.entity_radius).floor().to_int()
  let max_x = (pos[0] + self.entity_radius).floor().to_int()
  let min_z = (pos[2] - self.entity_radius).floor().to_int()
  let max_z = (pos[2] + self.entity_radius).floor().to_int()
  for bx in min_x..<=max_x {
    for bz in min_z..<=max_z {
      for box in self.block_boxes_at(bx, block_y, bz) {
        let top = block_y.to_double() + box.max[1].to_double()
        if top > foot_y - GROUND_PROBE_TOLERANCE &&
          top <= foot_y + GROUND_PROBE_TOLERANCE {
          return true
        }
      }
    }
  }
  false
}

///|
fn aabb_overlap(
  a_min : Array[Double],
  a_max : Array[Double],
  b_min : Array[Double],
  b_max : Array[Double],
) -> Bool {
  a_max[0] > b_min[0] &&
  a_min[0] < b_max[0] &&
  a_max[1] > b_min[1] &&
  a_min[1] < b_max[1] &&
  a_max[2] > b_min[2] &&
  a_min[2] < b_max[2]
}

///|
/// Collision boxes of the selectable block at (wx, wy, wz), if any.
fn PlayerCollider::block_boxes_at(
  self : PlayerCollider,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Array[@shape.Box] {
  @level.get_block_id(self.chunk_map, self.size, wx, wy, wz)
  .bind(id => @block.lookup_by_internal_id(id))
  .map_or([], block => if block.is_selectable() { block.collision_boxes() } else { [] })
}

///|
/// The world-space AABB of the player after moving to `next` along `axis`.
/// Horizontal movement keeps the vertical extents fixed at `pos`; vertical
/// movement places the feet at `next` with the head `entity_height` above.
fn PlayerCollider::bounds_at(
  self : PlayerCollider,
  pos : Array[Double],
  axis : Int,
  next : Double,
) -> (Array[Double], Array[Double]) {
  let ent_min = [pos[0], pos[1], pos[2]]
  let ent_max = [pos[0], pos[1], pos[2]]
  if axis == 1 {
    ent_min[1] = next
    ent_max[1] = next + self.entity_height
  } else {
    ent_min[axis] = next - self.entity_radius
    ent_max[axis] = next + self.entity_radius
    ent_max[1] = pos[1] + self.entity_height
  }
  (ent_min, ent_max)
}

///|
/// Block coordinate of the leading edge of the player AABB along `axis`.
fn PlayerCollider::leading_block_coord(
  self : PlayerCollider,
  axis : Int,
  next : Double,
  dir : Int,
) -> Int {
  let target = if axis == 1 {
    if dir > 0 {
      next + self.entity_height
    } else {
      next
    }
  } else {
    next + dir.to_double() * self.entity_radius
  }
  target.floor().to_int()
}

///|
/// The block coordinate range swept on a perpendicular axis: vertical sweeps
/// span the entity height, horizontal sweeps span the entity radius.
fn PlayerCollider::sweep_bounds(
  self : PlayerCollider,
  pos : Array[Double],
  axis : Int,
) -> (Int, Int) {
  if axis == 1 {
    (pos[1].floor().to_int(), (pos[1] + self.entity_height).floor().to_int())
  } else {
    (
      (pos[axis] - self.entity_radius).floor().to_int(),
      (pos[axis] + self.entity_radius).floor().to_int(),
    )
  }
}

///|
/// Move along `axis` by `delta`, resolving collisions against solid block
/// AABBs. Returns the clamped new coordinate on that axis.
fn PlayerCollider::move_axis(
  self : PlayerCollider,
  pos : Array[Double],
  axis : Int,
  delta : Double,
) -> Double {
  guard delta != 0.0 else { pos[axis] }
  let dir = if delta > 0.0 { 1 } else { -1 }
  let mut next = pos[axis] + delta
  let eps = 0.0001
  let (ent_min, ent_max) = self.bounds_at(pos, axis, next)
  let block_axis = self.leading_block_coord(axis, next, dir)
  // Sweep order matches the axis-major iteration: vertical outer loop for
  // horizontal movement, horizontal outer loop for vertical movement.
  let outer = if axis == 1 { 0 } else { 1 }
  let inner = 3 - axis - outer
  let (min_outer, max_outer) = self.sweep_bounds(pos, outer)
  let (min_inner, max_inner) = self.sweep_bounds(pos, inner)
  for b_outer in min_outer..<=max_outer {
    for b_inner in min_inner..<=max_inner {
      let bx = if axis == 0 {
        block_axis
      } else if outer == 0 {
        b_outer
      } else {
        b_inner
      }
      let by = if axis == 1 { block_axis } else { b_outer }
      let bz = if axis == 2 {
        block_axis
      } else if inner == 2 {
        b_inner
      } else {
        b_outer
      }
      for box in self.block_boxes_at(bx, by, bz) {
        let b_min = [
          bx.to_double() + box.min[0].to_double(),
          by.to_double() + box.min[1].to_double(),
          bz.to_double() + box.min[2].to_double(),
        ]
        let b_max = [
          bx.to_double() + box.max[0].to_double(),
          by.to_double() + box.max[1].to_double(),
          bz.to_double() + box.max[2].to_double(),
        ]
        guard aabb_overlap(ent_min, ent_max, b_min, b_max) else { continue }
        if axis == 1 {
          next = if dir > 0 {
            b_min[1] - self.entity_height - eps
          } else {
            b_max[1] + eps
          }
        } else {
          next = if dir > 0 {
            b_min[axis] - self.entity_radius - eps
          } else {
            b_max[axis] + self.entity_radius + eps
          }
        }
        return next
      }
    }
  }
  next
}
