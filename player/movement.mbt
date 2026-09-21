///|
/// Input snapshot for player movement.
pub struct MoveInput {
  forward : Bool
  back : Bool
  left : Bool
  right : Bool
  up : Bool
  down : Bool
  sprint : Bool
  fast : Bool
}

///|
pub fn MoveInput::new(
  forward? : Bool = false,
  back? : Bool = false,
  left? : Bool = false,
  right? : Bool = false,
  up? : Bool = false,
  down? : Bool = false,
  sprint? : Bool = false,
  fast? : Bool = false,
) -> MoveInput {
  { forward, back, left, right, up, down, sprint, fast, }
}

///|
/// Downward acceleration in blocks per second squared.
const GRAVITY : Double = 32.0

///|
/// Maximum falling speed in blocks per second.
const TERMINAL_VELOCITY : Double = 78.4

///|
/// Upward speed applied when a grounded player jumps.
const JUMP_SPEED : Double = 9.0

///|
/// Reduced gravity while submerged.
const WATER_GRAVITY : Double = 4.0

///|
/// Maximum sinking speed while submerged.
const WATER_TERMINAL_VELOCITY : Double = 4.0

///|
/// Upward swim speed while submerged and pressing up.
const WATER_JUMP_SPEED : Double = 4.0

///|
/// Ground contact tolerance in blocks.
const GROUND_PROBE_TOLERANCE : Double = 0.05

///|
/// Result of one movement step, including the vertical state needed for
/// gravity, grounding, and fall damage.
pub struct PlayerMotion {
  position : Array[Double]
  velocity_y : Double
  on_ground : Bool
  fall_distance : Double
  jumped : Bool
} derive(Debug)

///|
fn resting_motion(position : Array[Double]) -> PlayerMotion {
  {
    position,
    velocity_y: 0.0,
    on_ground: false,
    fall_distance: 0.0,
    jumped: false,
  }
}

///|
/// Whether a solid face sits directly below the player's feet.
fn is_on_ground(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  pos : Array[Double],
  entity_radius : Double,
) -> Bool {
  let foot_y = pos[1]
  let block_y = (foot_y - GROUND_PROBE_TOLERANCE).floor().to_int()
  let min_x = (pos[0] - entity_radius).floor().to_int()
  let max_x = (pos[0] + entity_radius).floor().to_int()
  let min_z = (pos[2] - entity_radius).floor().to_int()
  let max_z = (pos[2] + entity_radius).floor().to_int()
  for bx in min_x..<=max_x {
    for bz in min_z..<=max_z {
      guard get_block_boxes_at(chunk_map, size, bx, block_y, bz) is Some(boxes) else {
        continue
      }
      for box in boxes {
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
fn get_block_boxes_at(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Array[@shape.Box]? {
  @level.get_block_id(chunk_map, size, wx, wy, wz)
  .bind(id => {
    if id == @schema.AIR_ID {
      None
    } else {
      @block.lookup_by_internal_id(id).bind(block => {
        if block.is_selectable() {
          Some(id)
        } else {
          None
        }
      })
    }
  })
  .bind(id => @block.get_shape_desc(id))
  .bind(desc => if desc.boxes.length() > 0 { Some(desc.boxes) } else { None })
}

///|
/// The world-space AABB of the player after moving to `next` along `axis`.
/// Horizontal movement keeps the vertical extents fixed at `pos`; vertical
/// movement places the feet at `next` with the head `entity_height` above.
fn player_aabb_at(
  pos : Array[Double],
  axis : Int,
  next : Double,
  entity_height : Double,
  entity_radius : Double,
) -> (Array[Double], Array[Double]) {
  let ent_min = [pos[0], pos[1], pos[2]]
  let ent_max = [pos[0], pos[1], pos[2]]
  if axis == 1 {
    ent_min[1] = next
    ent_max[1] = next + entity_height
  } else {
    ent_min[axis] = next - entity_radius
    ent_max[axis] = next + entity_radius
    ent_max[1] = pos[1] + entity_height
  }
  (ent_min, ent_max)
}

///|
/// Block coordinate of the leading edge of the player AABB along `axis`.
fn leading_block_coord(
  axis : Int,
  next : Double,
  dir : Int,
  entity_height : Double,
  entity_radius : Double,
) -> Int {
  let target = if axis == 1 {
    if dir > 0 {
      next + entity_height
    } else {
      next
    }
  } else {
    next + dir.to_double() * entity_radius
  }
  target.floor().to_int()
}

///|
/// The block coordinate range swept on a perpendicular axis: vertical sweeps
/// span the entity height, horizontal sweeps span the entity radius.
fn sweep_bounds(
  pos : Array[Double],
  axis : Int,
  entity_height : Double,
  entity_radius : Double,
) -> (Int, Int) {
  if axis == 1 {
    (pos[1].floor().to_int(), (pos[1] + entity_height).floor().to_int())
  } else {
    (
      (pos[axis] - entity_radius).floor().to_int(),
      (pos[axis] + entity_radius).floor().to_int(),
    )
  }
}

///|
/// Move along `axis` by `delta`, resolving collisions against solid block
/// AABBs. Returns the clamped new coordinate on that axis.
fn move_axis(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  pos : Array[Double],
  axis : Int,
  delta : Double,
  entity_height : Double,
  entity_radius : Double,
) -> Double {
  guard delta != 0.0 else { pos[axis] }
  let dir = if delta > 0.0 { 1 } else { -1 }
  let mut next = pos[axis] + delta
  let eps = 0.0001
  let (ent_min, ent_max) = player_aabb_at(
    pos, axis, next, entity_height, entity_radius,
  )
  let block_axis = leading_block_coord(
    axis, next, dir, entity_height, entity_radius,
  )
  // Sweep order matches the axis-major iteration: vertical outer loop for
  // horizontal movement, horizontal outer loop for vertical movement.
  let outer = if axis == 1 { 0 } else { 1 }
  let inner = 3 - axis - outer
  let (min_outer, max_outer) = sweep_bounds(
    pos, outer, entity_height, entity_radius,
  )
  let (min_inner, max_inner) = sweep_bounds(
    pos, inner, entity_height, entity_radius,
  )
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
      guard get_block_boxes_at(chunk_map, size, bx, by, bz) is Some(boxes) else {
        continue
      }
      for box in boxes {
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
            b_min[1] - entity_height - eps
          } else {
            b_max[1] + eps
          }
        } else {
          next = if dir > 0 {
            b_min[axis] - entity_radius - eps
          } else {
            b_max[axis] + entity_radius + eps
          }
        }
        return next
      }
    }
  }
  next
}

///|
/// Move the player with collision resolution for solid blocks, applying
/// gravity and jumping for non-spectator game modes.
pub fn move_player(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  position : Array[Double],
  yaw : Double,
  input : MoveInput,
  speed : Double,
  delta : Double,
  entity_height : Double,
  entity_radius : Double,
  world_min_y : Int,
  game_mode : String,
  velocity_y : Double,
  fall_distance : Double,
  flying : Bool,
) -> PlayerMotion {
  guard position.length() >= 3 else { return resting_motion([0.0, 0.0, 0.0]) }
  let forward = [@math.cos(yaw), 0.0, @math.sin(yaw)]
  let right = [-forward[2], 0.0, forward[0]]
  let in_water = is_player_in_water(
    chunk_map,
    size,
    position[0],
    position[1],
    position[2],
    entity_height,
    entity_radius,
  )
  let mut velocity = speed * delta
  if in_water {
    velocity = velocity * 0.45
  }
  if input.fast {
    velocity = velocity * 2.0
  }
  if input.sprint && input.forward {
    velocity = velocity * 2.0
  }
  let mut dx = 0.0
  let mut dz = 0.0
  if input.forward {
    dx = dx + forward[0] * velocity
    dz = dz + forward[2] * velocity
  }
  if input.back {
    dx = dx - forward[0] * velocity
    dz = dz - forward[2] * velocity
  }
  if input.left {
    dx = dx - right[0] * velocity
    dz = dz - right[2] * velocity
  }
  if input.right {
    dx = dx + right[0] * velocity
    dz = dz + right[2] * velocity
  }
  let mut x = position[0]
  let mut y = position[1]
  let mut z = position[2]
  if game_mode == "spectator" {
    x = x + dx
    z = z + dz
    y = y +
      (if input.up { velocity } else if input.down { -velocity } else { 0.0 })
    return resting_motion([x, y, z])
  }
  if flying {
    x = move_axis(
      chunk_map,
      size,
      [x, y, z],
      0,
      dx,
      entity_height,
      entity_radius,
    )
    z = move_axis(
      chunk_map,
      size,
      [x, y, z],
      2,
      dz,
      entity_height,
      entity_radius,
    )
    let dy = if input.up {
      velocity
    } else if input.down {
      -velocity
    } else {
      0.0
    }
    y = move_axis(
      chunk_map,
      size,
      [x, y, z],
      1,
      dy,
      entity_height,
      entity_radius,
    )
    let min_y = world_min_y.to_double() - 1.0
    if y < min_y {
      y = min_y
    }
    return resting_motion([x, y, z])
  }
  x = move_axis(chunk_map, size, [x, y, z], 0, dx, entity_height, entity_radius)
  z = move_axis(chunk_map, size, [x, y, z], 2, dz, entity_height, entity_radius)
  let grounded = is_on_ground(chunk_map, size, [x, y, z], entity_radius)
  let mut vy = velocity_y
  let mut jumped = false
  let mut fall = fall_distance
  if in_water {
    vy = (vy - WATER_GRAVITY * delta).max(-WATER_TERMINAL_VELOCITY)
    if input.up {
      vy = WATER_JUMP_SPEED
    }
    fall = 0.0
  } else if grounded {
    if input.up {
      vy = JUMP_SPEED
      jumped = true
    } else {
      vy = 0.0
    }
    fall = 0.0
  } else {
    vy = (vy - GRAVITY * delta).max(-TERMINAL_VELOCITY)
  }
  let requested_y = y + vy * delta
  let resolved_y = move_axis(
    chunk_map,
    size,
    [x, y, z],
    1,
    vy * delta,
    entity_height,
    entity_radius,
  )
  let mut on_ground = false
  if vy < 0.0 {
    if resolved_y > requested_y {
      on_ground = true
      vy = 0.0
    } else {
      fall = fall + (y - resolved_y)
    }
  } else if vy == 0.0 {
    on_ground = grounded
  } else if resolved_y < requested_y {
    vy = 0.0
  }
  y = resolved_y
  let min_y = world_min_y.to_double() - 1.0
  if y < min_y {
    y = min_y
  }
  {
    position: [x, y, z],
    velocity_y: vy,
    on_ground,
    fall_distance: fall,
    jumped,
  }
}
