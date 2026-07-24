///|
const POSITION_EPSILON : Double = 0.00001

///|
priv struct MovementPlan {
  waypoints : Array[EntityPosition]
  mut next_index : Int
  mut started : Bool
}

///|
priv struct EntityState {
  id : String
  mut position : EntityPosition
  mut yaw : Double
  render_y_offset : Double
  move_speed : Double
  turn_speed : Double
  mut movement : MovementPlan?
}

///|
fn EntityState::new(id : String, spawn : EntitySpawn) -> EntityState {
  {
    id,
    position: spawn.position,
    yaw: 0.0,
    render_y_offset: spawn.render_y_offset,
    move_speed: spawn.move_speed,
    turn_speed: spawn.turn_speed,
    movement: None,
  }
}

///|
fn distance_to(a : EntityPosition, b : EntityPosition) -> Double {
  let dx = b.x - a.x
  let dy = b.y - a.y
  let dz = b.z - a.z
  (dx * dx + dy * dy + dz * dz).sqrt()
}

///|
fn target_yaw(a : EntityPosition, b : EntityPosition) -> Double? {
  let dx = b.x - a.x
  let dz = b.z - a.z
  guard dx.abs() > POSITION_EPSILON || dz.abs() > POSITION_EPSILON else { None }
  Some(@math.atan2(dz, dx))
}

///|
fn shortest_angle_delta(current : Double, target : Double) -> Double {
  let full_turn = @math.PI * 2.0
  let mut delta = target - current
  while delta > @math.PI {
    delta -= full_turn
  }
  while delta < -@math.PI {
    delta += full_turn
  }
  delta
}

///|
fn EntityState::turn_toward(
  self : EntityState,
  target : Double,
  delta : Double,
) -> Unit {
  let angle = shortest_angle_delta(self.yaw, target)
  let max_turn = self.turn_speed * delta
  if angle.abs() <= max_turn {
    self.yaw = target
  } else if angle > 0.0 {
    self.yaw += max_turn
  } else {
    self.yaw -= max_turn
  }
}

///|
fn EntityState::advance(
  self : EntityState,
  delta : Double,
) -> Array[EntityEvent] {
  let events = []
  guard delta > 0.0 else { events }
  let mut remaining = delta
  while remaining > 0.0 {
    guard self.movement is Some(plan) else { break }
    guard plan.waypoints.get(plan.next_index) is Some(target) else {
      self.movement = None
      events.push(EntityEvent::MovementCompleted(self.id))
      break
    }
    let distance = distance_to(self.position, target)
    match target_yaw(self.position, target) {
      Some(yaw) => self.turn_toward(yaw, remaining)
      None => ()
    }
    if distance <= POSITION_EPSILON {
      self.position = target
      let reached = plan.next_index
      plan.next_index += 1
      events.push(EntityEvent::WaypointReached(self.id, reached))
      continue
    }
    let travel = self.move_speed * remaining
    if travel >= distance {
      self.position = target
      remaining -= distance / self.move_speed
      let reached = plan.next_index
      plan.next_index += 1
      events.push(EntityEvent::WaypointReached(self.id, reached))
    } else {
      let ratio = travel / distance
      self.position = EntityPosition::new(
        self.position.x + (target.x - self.position.x) * ratio,
        self.position.y + (target.y - self.position.y) * ratio,
        self.position.z + (target.z - self.position.z) * ratio,
      )
      remaining = 0.0
    }
  }
  guard self.movement is Some(plan) else { events }
  guard plan.next_index >= plan.waypoints.length() else { events }
  self.movement = None
  events.push(EntityEvent::MovementCompleted(self.id))
  events
}

///|
fn EntityState::set_path(
  self : EntityState,
  waypoints : Array[EntityPosition],
) -> Bool {
  guard self.move_speed > 0.0 && !waypoints.is_empty() else { false }
  self.movement = Some({ waypoints, next_index: 0, started: false })
  true
}

///|
fn EntityState::snapshot(self : EntityState) -> EntitySnapshot {
  {
    id: self.id,
    position: self.position,
    yaw: self.yaw,
    render_y_offset: self.render_y_offset,
  }
}
