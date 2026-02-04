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
fn intersects(
  a_min_x : Double,
  a_min_y : Double,
  a_min_z : Double,
  a_max_x : Double,
  a_max_y : Double,
  a_max_z : Double,
  b_min_x : Double,
  b_min_y : Double,
  b_min_z : Double,
  b_max_x : Double,
  b_max_y : Double,
  b_max_z : Double,
) -> Bool {
  a_max_x > b_min_x &&
  a_min_x < b_max_x &&
  a_max_y > b_min_y &&
  a_min_y < b_max_y &&
  a_max_z > b_min_z &&
  a_min_z < b_max_z
}

///|
fn get_block_boxes_at(
  chunk_map : @ffi.JsValue,
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Array[@block.ShapeBox]? {
  match @level.get_block_id(chunk_map, size, wx, wy, wz) {
    None => None
    Some(id) =>
      if id == @block.AIR_LONG_ID {
        None
      } else {
        match @block.lookup_by_long_id(id) {
          Some(block) if block.is_selectable() =>
            match @block.get_shape_desc(id) {
              Some(desc) =>
                if desc.boxes.length() > 0 {
                  Some(desc.boxes)
                } else {
                  None
                }
              None => None
            }
          _ => None
        }
      }
  }
}

///|
fn move_axis(
  chunk_map : @ffi.JsValue,
  size : Int,
  pos : Array[Double],
  axis : Int,
  delta : Double,
  entity_height : Double,
  entity_radius : Double,
) -> Double {
  if delta == 0.0 {
    return pos[axis]
  }
  let radius = entity_radius
  let height = entity_height
  let dir = if delta > 0.0 { 1 } else { -1 }
  let mut next = pos[axis] + delta
  let eps = 0.0001
  if axis == 0 {
    let target_x = next + dir.to_double() * radius
    let block_x = target_x.floor().to_int()
    let min_y = pos[1].floor().to_int()
    let max_y = (pos[1] + height).floor().to_int()
    let min_z = (pos[2] - radius).floor().to_int()
    let max_z = (pos[2] + radius).floor().to_int()
    let ent_min_x = next - radius
    let ent_max_x = next + radius
    let ent_min_y = pos[1]
    let ent_max_y = pos[1] + height
    let ent_min_z = pos[2] - radius
    let ent_max_z = pos[2] + radius
    for by in min_y..<=max_y {
      for bz in min_z..<=max_z {
        match get_block_boxes_at(chunk_map, size, block_x, by, bz) {
          None => ()
          Some(boxes) =>
            for box in boxes {
              let b_min_x = block_x.to_double() + box.min[0].to_double()
              let b_max_x = block_x.to_double() + box.max[0].to_double()
              let b_min_y = by.to_double() + box.min[1].to_double()
              let b_max_y = by.to_double() + box.max[1].to_double()
              let b_min_z = bz.to_double() + box.min[2].to_double()
              let b_max_z = bz.to_double() + box.max[2].to_double()
              if !intersects(
                  ent_min_x, ent_min_y, ent_min_z, ent_max_x, ent_max_y, ent_max_z,
                  b_min_x, b_min_y, b_min_z, b_max_x, b_max_y, b_max_z,
                ) {
                continue
              }
              next = if dir > 0 {
                b_min_x - radius - eps
              } else {
                b_max_x + radius + eps
              }
              return next
            }
        }
      }
    }
    next
  } else if axis == 2 {
    let target_z = next + dir.to_double() * radius
    let block_z = target_z.floor().to_int()
    let min_y = pos[1].floor().to_int()
    let max_y = (pos[1] + height).floor().to_int()
    let min_x = (pos[0] - radius).floor().to_int()
    let max_x = (pos[0] + radius).floor().to_int()
    let ent_min_x = pos[0] - radius
    let ent_max_x = pos[0] + radius
    let ent_min_y = pos[1]
    let ent_max_y = pos[1] + height
    let ent_min_z = next - radius
    let ent_max_z = next + radius
    for by in min_y..<=max_y {
      for bx in min_x..<=max_x {
        match get_block_boxes_at(chunk_map, size, bx, by, block_z) {
          None => ()
          Some(boxes) =>
            for box in boxes {
              let b_min_x = bx.to_double() + box.min[0].to_double()
              let b_max_x = bx.to_double() + box.max[0].to_double()
              let b_min_y = by.to_double() + box.min[1].to_double()
              let b_max_y = by.to_double() + box.max[1].to_double()
              let b_min_z = block_z.to_double() + box.min[2].to_double()
              let b_max_z = block_z.to_double() + box.max[2].to_double()
              if !intersects(
                  ent_min_x, ent_min_y, ent_min_z, ent_max_x, ent_max_y, ent_max_z,
                  b_min_x, b_min_y, b_min_z, b_max_x, b_max_y, b_max_z,
                ) {
                continue
              }
              next = if dir > 0 {
                b_min_z - radius - eps
              } else {
                b_max_z + radius + eps
              }
              return next
            }
        }
      }
    }
    next
  } else if axis == 1 {
    let target_y = if dir > 0 { next + height } else { next }
    let block_y = target_y.floor().to_int()
    let min_x = (pos[0] - radius).floor().to_int()
    let max_x = (pos[0] + radius).floor().to_int()
    let min_z = (pos[2] - radius).floor().to_int()
    let max_z = (pos[2] + radius).floor().to_int()
    let ent_min_x = pos[0] - radius
    let ent_max_x = pos[0] + radius
    let ent_min_y = next
    let ent_max_y = next + height
    let ent_min_z = pos[2] - radius
    let ent_max_z = pos[2] + radius
    for bx in min_x..<=max_x {
      for bz in min_z..<=max_z {
        match get_block_boxes_at(chunk_map, size, bx, block_y, bz) {
          None => ()
          Some(boxes) =>
            for box in boxes {
              let b_min_x = bx.to_double() + box.min[0].to_double()
              let b_max_x = bx.to_double() + box.max[0].to_double()
              let b_min_y = block_y.to_double() + box.min[1].to_double()
              let b_max_y = block_y.to_double() + box.max[1].to_double()
              let b_min_z = bz.to_double() + box.min[2].to_double()
              let b_max_z = bz.to_double() + box.max[2].to_double()
              if !intersects(
                  ent_min_x, ent_min_y, ent_min_z, ent_max_x, ent_max_y, ent_max_z,
                  b_min_x, b_min_y, b_min_z, b_max_x, b_max_y, b_max_z,
                ) {
                continue
              }
              next = if dir > 0 {
                b_min_y - height - eps
              } else {
                b_max_y + eps
              }
              return next
            }
        }
      }
    }
    next
  } else {
    next
  }
}

///|
/// Move the player with collision resolution for solid blocks.
pub fn move_player(
  chunk_map : @ffi.JsValue,
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
) -> Array[Double] {
  if position.length() < 3 {
    return [0.0, 0.0, 0.0]
  }
  let input = MoveInput::{
    forward: input.forward,
    back: input.back,
    left: input.left,
    right: input.right,
    up: input.up,
    down: input.down,
    sprint: input.sprint,
    fast: input.fast,
  }
  let forward = [@math.cos(yaw), 0.0, @math.sin(yaw)]
  let right = [-forward[2], 0.0, forward[0]]
  let mut velocity = speed * delta
  if input.fast {
    velocity = velocity * 2.0
  }
  if input.sprint && input.forward {
    velocity = velocity * 2.0
  }
  let mut dx = 0.0
  let mut dy = 0.0
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
  if input.up {
    dy = dy + velocity
  }
  if input.down {
    dy = dy - velocity
  }
  let mut x = position[0]
  let mut y = position[1]
  let mut z = position[2]
  if game_mode is "spectator" {
    x = x + dx
    y = y + dy
    z = z + dz
  } else {
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
    y = move_axis(
      chunk_map,
      size,
      [x, y, z],
      1,
      dy,
      entity_height,
      entity_radius,
    )
  }
  let min_y = world_min_y.to_double() - 1.0
  if y < min_y {
    y = min_y
  }
  [x, y, z]
}
