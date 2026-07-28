///|
pub struct EntityRuntime {
  priv entities : Map[String, EntityState]
}

///|
pub fn EntityRuntime::new() -> EntityRuntime {
  { entities: {} }
}

///|
pub fn EntityRuntime::spawn(self : EntityRuntime, spawn : EntitySpawn) -> Bool {
  guard !self.entities.contains(spawn.id) else { false }
  self.entities[spawn.id] = EntityState::new(spawn)
  true
}

///|
pub fn EntityRuntime::kind(self : EntityRuntime, id : String) -> EntityKind? {
  self.entities.get(id).map(entity => entity.kind)
}

///|
pub fn EntityRuntime::position(
  self : EntityRuntime,
  id : String,
) -> EntityPosition? {
  self.entities.get(id).map(entity => entity.position)
}

///|
pub fn EntityRuntime::set_path(
  self : EntityRuntime,
  id : String,
  waypoints : Array[EntityPosition],
) -> Bool {
  guard self.entities.get(id) is Some(entity) else { false }
  entity.set_path(waypoints)
}

///|
pub fn EntityRuntime::cancel_movement(
  self : EntityRuntime,
  id : String,
) -> EntityEvent? {
  guard self.entities.get(id) is Some(entity) else { None }
  guard entity.movement is Some(_) else { None }
  entity.movement = None
  Some(EntityEvent::MovementCancelled(id))
}

///|
pub fn EntityRuntime::tick(
  self : EntityRuntime,
  delta : Double,
) -> Array[EntityEvent] {
  let events = []
  for id in self.entities.keys() {
    guard self.entities.get(id) is Some(entity) else { continue }
    match entity.movement {
      Some(plan) => {
        if !plan.started {
          plan.started = true
          events.push(EntityEvent::MovementStarted(id))
        }
        events.append(entity.advance(delta))
      }
      None => ()
    }
  }
  events
}

///|
pub fn EntityRuntime::snapshots(self : EntityRuntime) -> Array[EntitySnapshot] {
  self.entities.values().map(entity => entity.snapshot()).to_array()
}

///|
pub fn EntityRuntime::save_entities(self : EntityRuntime) -> Array[EntitySave] {
  self.entities.values().map(entity => entity.save()).to_array()
}

///|
pub fn EntityRuntime::restore_entities(
  self : EntityRuntime,
  saved_entities : Array[EntitySave],
) -> Unit {
  self.entities.clear()
  for saved in saved_entities {
    self.entities[saved.id] = EntityState::from_save(saved)
  }
}
