///|
fn save_json_object(value : Json) -> Map[String, Json] {
  match value {
    Object(fields) => fields
    _ => Map([])
  }
}

///|
fn save_json_array(value : Json) -> Array[Json] {
  match value {
    Array(values) => values
    _ => []
  }
}

///|
fn save_json_field(fields : Map[String, Json], name : String) -> Json {
  fields.get(name).unwrap_or(Json::null())
}

///|
fn save_json_string(value : Json, fallback? : String = "") -> String {
  match value {
    String(value) => value
    _ => fallback
  }
}

///|
fn save_json_double(value : Json, fallback? : Double = 0.0) -> Double {
  match value {
    Number(value, ..) => value
    _ => fallback
  }
}

///|
fn save_json_int(value : Json, fallback? : Int = 0) -> Int {
  save_json_double(value, fallback=fallback.to_double()).floor().to_int()
}

///|
fn save_json_bool(value : Json, fallback? : Bool = false) -> Bool {
  match value {
    True => true
    False => false
    _ => fallback
  }
}

///|
fn save_json_fallback(first : Json, second : Json) -> Json {
  if first is Null {
    second
  } else {
    first
  }
}

///|
fn parse_slot(value : Json) -> @player.HotbarSlot? {
  let fields = save_json_object(value)
  let name = save_json_string(save_json_field(fields, "name"))
  guard name.length() > 0 else { None }
  Some(
    @player.HotbarSlot::new(
      name,
      save_json_string(save_json_field(fields, "category"), fallback="none"),
    ),
  )
}

///|
fn parse_inventory(
  runtime : Map[String, Json],
) -> @player.PlayerInventorySnapshot {
  let canonical = save_json_object(save_json_field(runtime, "inventory"))
  let player = save_json_object(save_json_field(runtime, "player"))
  let hotbar = save_json_object(save_json_field(runtime, "hotbar"))
  let ui = save_json_object(save_json_field(runtime, "ui"))
  let game_mode = save_json_string(
    save_json_fallback(
      save_json_field(canonical, "game_mode"),
      save_json_fallback(
        save_json_field(runtime, "gameMode"),
        save_json_field(player, "gameMode"),
      ),
    ),
    fallback="creative",
  )
  let selected = save_json_int(
    save_json_fallback(
      save_json_field(canonical, "selected_hotbar_index"),
      save_json_field(hotbar, "selectedIndex"),
    ),
  )
  let raw_slots = save_json_fallback(
    save_json_field(canonical, "hotbar_slots"),
    save_json_field(hotbar, "items"),
  )
  let slots = save_json_array(raw_slots).map(parse_slot)
  let inventory_open = save_json_bool(
    save_json_fallback(
      save_json_field(canonical, "inventory_open"),
      save_json_fallback(
        save_json_field(ui, "inventoryOpen"),
        save_json_field(runtime, "inventoryOpen"),
      ),
    ),
  )
  let inventory = @player.PlayerInventoryRuntime::new(game_mode~, slots~)
  ignore(inventory.select_hotbar(selected))
  ignore(inventory.set_inventory_open(inventory_open))
  inventory.snapshot()
}

///|
fn parse_player(
  root : Map[String, Json],
  runtime : Map[String, Json],
) -> SavePlayer {
  let fields = save_json_object(
    save_json_fallback(
      save_json_field(root, "player"),
      save_json_field(runtime, "player"),
    ),
  )
  let raw_position = save_json_array(save_json_field(fields, "position"))
  let position = if raw_position.length() >= 3 {
    [
      save_json_double(raw_position[0]),
      save_json_double(raw_position[1]),
      save_json_double(raw_position[2]),
    ]
  } else {
    [0.0, 0.0, 0.0]
  }
  {
    position,
    yaw: save_json_double(save_json_field(fields, "yaw")),
    pitch: save_json_double(save_json_field(fields, "pitch")),
  }
}

///|
fn parse_deltas(root : Map[String, Json]) -> Array[@render.BlockDelta] {
  let values = save_json_array(
    save_json_fallback(
      save_json_field(root, "block_deltas"),
      save_json_field(root, "blockDeltas"),
    ),
  )
  let deltas : Array[@render.BlockDelta] = []
  for value in values {
    let fields = save_json_object(value)
    let x = save_json_int(
      save_json_fallback(
        save_json_field(fields, "x"),
        save_json_field(fields, "wx"),
      ),
    )
    let y = save_json_int(
      save_json_fallback(
        save_json_field(fields, "y"),
        save_json_field(fields, "wy"),
      ),
    )
    let z = save_json_int(
      save_json_fallback(
        save_json_field(fields, "z"),
        save_json_field(fields, "wz"),
      ),
    )
    let id = save_json_int(save_json_field(fields, "id"))
    guard id >= 0 else { continue }
    deltas.push(@render.BlockDelta::new(x, y, z, id.reinterpret_as_uint()))
  }
  deltas
}

///|
fn migrate_json(root_value : Json) -> SavePayload? {
  let root = save_json_object(root_value)
  guard root.length() > 0 else { None }
  let world = save_json_object(save_json_field(root, "world"))
  let seed = save_json_int(
    save_json_fallback(
      save_json_field(world, "seed"),
      save_json_field(root, "seed"),
    ),
  )
  let world_type = save_json_string(
    save_json_fallback(
      save_json_field(world, "world_type"),
      save_json_field(world, "worldType"),
    ),
  )
  guard seed >= 0 && world_type.length() > 0 else { None }
  let runtime = save_json_object(save_json_field(root, "runtime"))
  Some(SavePayload::{
    version: SAVE_SCHEMA_VERSION,
    saved_at: save_json_double(
      save_json_fallback(
        save_json_field(root, "saved_at"),
        save_json_field(root, "savedAt"),
      ),
    ),
    world: { seed: seed.reinterpret_as_uint(), world_type },
    player: parse_player(root, runtime),
    inventory: parse_inventory(runtime),
    block_deltas: parse_deltas(root),
  })
}

///|
pub fn migrate_save_payload(text : String) -> SavePayload? {
  try @json.parse(text) catch {
    _ => None
  } noraise {
    root => migrate_json(root)
  }
}
