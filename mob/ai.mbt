///|
const PATH_SEARCH_EXPANSIONS_PER_TICK : Int = 96

///|
priv struct NavigationRequest {
  chunk_map : @hashmap.HashMap[String, Array[UInt]]
  size : Int
  target_wx : Int
  target_wz : Int
}

///|
pub fn MobRuntime::save_entities(
  self : MobRuntime,
) -> Array[@entity.EntitySave] {
  self.entity_runtime.save_entities()
}

///|
fn MobRuntime::reset(self : MobRuntime) -> Unit {
  self.entity_runtime.restore_entities([])
  self.navigation_requests.clear()
  self.path_searches.clear()
  self.pending_render_configs.clear()
}

///|
fn find_standable_y(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Int {
  for dy in 0..<4 {
    let candidate = wy - dy
    guard is_walkable(chunk_map, size, wx, candidate, wz) else { continue }
    return candidate
  }
  wy
}

///|
fn MobRuntime::request_navigation(
  self : MobRuntime,
  entity_id : String,
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  target_wx : Int,
  target_wz : Int,
) -> Unit {
  self.navigation_requests[entity_id] = {
    chunk_map,
    size,
    target_wx,
    target_wz,
  }
}

///|
pub fn MobRuntime::request_zombie_0_navigation(
  self : MobRuntime,
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  target_wx : Int,
  _target_wy : Int,
  target_wz : Int,
) -> Unit {
  self.request_navigation(ZOMBIE_0_ID, chunk_map, size, target_wx, target_wz)
}

///|
fn MobRuntime::start_path_search(
  self : MobRuntime,
  entity_id : String,
  request : NavigationRequest,
) -> Array[@entity.EntityEvent] {
  let events = []
  if self.entity_runtime.cancel_movement(entity_id) is Some(event) {
    events.push(event)
  }
  self.path_searches.remove(entity_id)
  guard self.entity_runtime.position(entity_id) is Some(position) else {
    events
  }
  let start_wx = position.x.floor().to_int()
  let start_wz = position.z.floor().to_int()
  let start_wy = find_standable_y(
    request.chunk_map,
    request.size,
    start_wx,
    position.y.floor().to_int(),
    start_wz,
  )
  self.path_searches[entity_id] = PathSearch::new(
    request.chunk_map,
    request.size,
    start_wx,
    start_wy,
    start_wz,
    request.target_wx,
    request.target_wz,
  )
  events
}

///|
fn MobRuntime::start_pending_path_searches(
  self : MobRuntime,
) -> Array[@entity.EntityEvent] {
  let events = []
  let requests = self.navigation_requests
    .keys()
    .to_array()
    .map(entity_id => (entity_id, self.navigation_requests[entity_id]))
  self.navigation_requests.clear()
  for request_entry in requests {
    let (entity_id, request) = request_entry
    events.append(self.start_path_search(entity_id, request))
  }
  events
}

///|
fn MobRuntime::apply_found_path(
  self : MobRuntime,
  entity_id : String,
  nodes : Array[PathNode],
) -> Unit {
  match nodes {
    [] => ()
    [_, .. waypoints] =>
      ignore(
        self.entity_runtime.set_path(
          entity_id,
          waypoints.map(node => {
            @entity.EntityPosition::new(
              node.wx.to_double() + 0.5,
              node.wy.to_double(),
              node.wz.to_double() + 0.5,
            )
          }),
        ),
      )
  }
}

///|
fn MobRuntime::tick_path_searches(self : MobRuntime) -> Unit {
  let entity_ids = self.path_searches.keys().to_array()
  for entity_id in entity_ids {
    guard self.path_searches.get(entity_id) is Some(search) else { continue }
    match search.advance(PATH_SEARCH_EXPANSIONS_PER_TICK) {
      InProgress => ()
      Found(path) => {
        self.path_searches.remove(entity_id)
        self.apply_found_path(entity_id, path)
      }
      Unreachable => {
        self.path_searches.remove(entity_id)
        @ffi.console_err("Cannot find a path for \{entity_id}")
      }
    }
  }
}

///|
fn MobRuntime::tick_ai(self : MobRuntime) -> Array[@entity.EntityEvent] {
  let events = self.start_pending_path_searches()
  self.tick_path_searches()
  events
}
