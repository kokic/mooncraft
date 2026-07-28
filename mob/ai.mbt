///|
const PATH_SEARCH_EXPANSIONS_PER_TICK : Int = 96

///|
priv struct NavigationRequest {
  chunk_map : @ffi.JsValue
  size : Int
  target_wx : Int
  target_wz : Int
}

///|
let entity_runtime : @entity.EntityRuntime = @entity.EntityRuntime::new()

///|
let navigation_requests : Map[String, NavigationRequest] = Map([])

///|
let path_searches : Map[String, PathSearch] = Map([])

///|
fn find_standable_y(
  chunk_map : @ffi.JsValue,
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
fn request_navigation(
  entity_id : String,
  chunk_map : @ffi.JsValue,
  size : Int,
  target_wx : Int,
  target_wz : Int,
) -> Unit {
  navigation_requests[entity_id] = { chunk_map, size, target_wx, target_wz }
}

///|
pub fn request_zombie_0_navigation(
  chunk_map : @ffi.JsValue,
  size : Int,
  target_wx : Int,
  _target_wy : Int,
  target_wz : Int,
) -> Unit {
  request_navigation(ZOMBIE_0_ID, chunk_map, size, target_wx, target_wz)
}

///|
fn start_path_search(
  entity_id : String,
  request : NavigationRequest,
) -> Array[@entity.EntityEvent] {
  let events = []
  match entity_runtime.cancel_movement(entity_id) {
    Some(event) => events.push(event)
    None => ()
  }
  path_searches.remove(entity_id)
  guard entity_runtime.position(entity_id) is Some(position) else { events }
  let start_wx = position.x.floor().to_int()
  let start_wz = position.z.floor().to_int()
  let start_wy = find_standable_y(
    request.chunk_map,
    request.size,
    start_wx,
    position.y.floor().to_int(),
    start_wz,
  )
  path_searches[entity_id] = PathSearch::new(
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
fn start_pending_path_searches() -> Array[@entity.EntityEvent] {
  let events = []
  let requests = navigation_requests
    .keys()
    .to_array()
    .map(entity_id => (entity_id, navigation_requests[entity_id]))
  navigation_requests.clear()
  for request_entry in requests {
    let (entity_id, request) = request_entry
    events.append(start_path_search(entity_id, request))
  }
  events
}

///|
fn apply_found_path(entity_id : String, nodes : Array[PathNode]) -> Unit {
  match nodes {
    [] => ()
    [_, .. waypoints] =>
      ignore(
        entity_runtime.set_path(
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
fn tick_path_searches() -> Unit {
  let entity_ids = path_searches.keys().to_array()
  for entity_id in entity_ids {
    guard path_searches.get(entity_id) is Some(search) else { continue }
    match search.advance(PATH_SEARCH_EXPANSIONS_PER_TICK) {
      InProgress => ()
      Found(path) => {
        path_searches.remove(entity_id)
        apply_found_path(entity_id, path)
      }
      Unreachable => {
        path_searches.remove(entity_id)
        @ffi.console_err("Cannot find a path for \{entity_id}")
      }
    }
  }
}

///|
fn tick_ai() -> Array[@entity.EntityEvent] {
  let events = start_pending_path_searches()
  tick_path_searches()
  events
}
