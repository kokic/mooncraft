///|
pub const SAVE_SCHEMA_VERSION : Int = 2

///|
pub struct SaveWorld {
  seed : UInt
  world_type : String
} derive(Debug, ToJson)

///|
pub struct SavePlayer {
  position : Array[Double]
  yaw : Double
  pitch : Double
} derive(Debug, ToJson)

///|
pub struct SavePayload {
  version : Int
  saved_at : Double
  world : SaveWorld
  player : SavePlayer
  inventory : @player.PlayerInventorySnapshot
  block_deltas : Array[@render.BlockDelta]
} derive(Debug, ToJson)

///|
pub fn SavePayload::new(
  saved_at : Double,
  seed : UInt,
  world_type : String,
  position : Array[Double],
  yaw : Double,
  pitch : Double,
  inventory : @player.PlayerInventorySnapshot,
  block_deltas : Array[@render.BlockDelta],
) -> SavePayload {
  let position = if position.length() >= 3 {
    [position[0], position[1], position[2]]
  } else {
    [0.0, 0.0, 0.0]
  }
  {
    version: SAVE_SCHEMA_VERSION,
    saved_at,
    world: { seed, world_type },
    player: { position, yaw, pitch },
    inventory,
    block_deltas,
  }
}

///|
pub fn SavePayload::matches_world(
  self : SavePayload,
  seed : UInt,
  world_type : String,
) -> Bool {
  self.world.seed == seed && self.world.world_type == world_type
}

///|
pub fn SavePayload::player(self : SavePayload) -> SavePlayer {
  self.player
}

///|
pub fn SavePayload::inventory(
  self : SavePayload,
) -> @player.PlayerInventorySnapshot {
  self.inventory
}

///|
pub fn SavePayload::block_deltas(
  self : SavePayload,
) -> Array[@render.BlockDelta] {
  self.block_deltas
}

///|
pub fn SavePayload::encode(self : SavePayload) -> String {
  self.to_json().stringify()
}
