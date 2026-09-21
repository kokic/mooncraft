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
  let collider = PlayerCollider::{ chunk_map, size, entity_height, entity_radius, }
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
  x = collider.move_axis([x, y, z], 0, dx)
  z = collider.move_axis([x, y, z], 2, dz)
  if flying {
    let dy = if input.up {
      velocity
    } else if input.down {
      -velocity
    } else {
      0.0
    }
    y = collider.move_axis([x, y, z], 1, dy)
    let min_y = world_min_y.to_double() - 1.0
    if y < min_y {
      y = min_y
    }
    return resting_motion([x, y, z])
  }
  let grounded = collider.is_on_ground([x, y, z])
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
  let resolved_y = collider.move_axis([x, y, z], 1, vy * delta)
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
