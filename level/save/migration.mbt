///|
struct SaveEnvelope {
  version : Int
} derive(FromJson)

///|
struct LevelSaveV1World {
  seed : UInt
  worldType : String
} derive(FromJson)

///|
struct LevelSaveV1Player {
  position : Array[Double]
  yaw : Double
  pitch : Double
} derive(FromJson)

///|
struct LevelSaveV1Hotbar {
  selectedIndex : Int
  items : Array[@player.HotbarSlot]
} derive(FromJson)

///|
struct LevelSaveV1Ui {
  inventoryOpen : Bool
} derive(FromJson)

///|
struct LevelSaveV1Runtime {
  player : LevelSaveV1Player
  gameMode : String
  hotbar : LevelSaveV1Hotbar
  ui : LevelSaveV1Ui
} derive(FromJson)

///|
struct LevelSaveV1BlockDelta {
  wx : Int
  wy : Int
  wz : Int
  id : UInt
} derive(FromJson)

///|
struct LevelSaveV1 {
  version : Int
  savedAt : Double
  world : LevelSaveV1World
  runtime : LevelSaveV1Runtime
  blockDeltas : Array[LevelSaveV1BlockDelta]
} derive(FromJson)

///|
fn LevelSaveV1::migrate(self : LevelSaveV1) -> SavePayload? {
  guard self.version == 1 && self.runtime.player.position.length() >= 3 else {
    return None
  }
  let inventory = @player.PlayerInventoryRuntime::new(
    game_mode=self.runtime.gameMode,
    slots=self.runtime.hotbar.items.map(slot => Some(slot)),
  )
  ignore(inventory.select_hotbar(self.runtime.hotbar.selectedIndex))
  ignore(inventory.set_inventory_open(self.runtime.ui.inventoryOpen))
  Some(
    SavePayload::new(
      self.savedAt,
      self.world.seed,
      self.world.worldType,
      self.runtime.player.position,
      self.runtime.player.yaw,
      self.runtime.player.pitch,
      inventory.snapshot(),
      self.blockDeltas.map(delta => {
        @render.BlockDelta::new(delta.wx, delta.wy, delta.wz, delta.id)
      }),
    ),
  )
}

///|
fn decode_current_level_save(root : Json) -> SavePayload? {
  try {
    let payload : SavePayload = @json.from_json(root)
    if payload.version == SAVE_SCHEMA_VERSION {
      Some(payload)
    } else {
      None
    }
  } catch {
    _ => None
  }
}

///|
fn decode_level_save_v1(root : Json) -> SavePayload? {
  try {
    let payload : LevelSaveV1 = @json.from_json(root)
    payload.migrate()
  } catch {
    _ => None
  }
}

///|
fn decode_level_save(root : Json) -> SavePayload? {
  try {
    let envelope : SaveEnvelope = @json.from_json(root)
    match envelope.version {
      1 => decode_level_save_v1(root)
      version if version == SAVE_SCHEMA_VERSION =>
        decode_current_level_save(root)
      _ => None
    }
  } catch {
    _ => None
  }
}

///|
pub fn migrate_save_payload(text : String) -> SavePayload? {
  try @json.parse(text) catch {
    _ => None
  } noraise {
    root => decode_level_save(root)
  }
}
