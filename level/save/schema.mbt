///|
pub const SAVE_SCHEMA_VERSION : Int = 3

///|
pub struct SaveWorld {
  seed : UInt
  world_type : String
  height : Int
} derive(Debug, ToJson, FromJson)

///|
pub struct SavePlayer {
  position : Array[Double]
  yaw : Double
  pitch : Double
} derive(Debug, ToJson, FromJson)

///|
pub struct SavePayload {
  version : Int
  saved_at : Double
  world : SaveWorld
  player : SavePlayer
  inventory : @player.PlayerInventorySnapshot
  block_deltas : Array[@level.BlockDelta]
} derive(Debug, ToJson, FromJson)

///|
pub fn SavePayload::new(
  saved_at : Double,
  seed : UInt,
  world_type : String,
  height : Int,
  position : Array[Double],
  yaw : Double,
  pitch : Double,
  inventory : @player.PlayerInventorySnapshot,
  block_deltas : Array[@level.BlockDelta],
) -> SavePayload {
  let position = if position.length() >= 3 {
    [position[0], position[1], position[2]]
  } else {
    [0.0, 0.0, 0.0]
  }
  {
    version: SAVE_SCHEMA_VERSION,
    saved_at,
    world: { seed, world_type, height },
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
  height : Int,
) -> Bool {
  self.world.seed == seed &&
  self.world.world_type == world_type &&
  self.world.height == height
}

///|
pub fn SavePayload::player(self : SavePayload) -> SavePlayer {
  self.player
}

///|
pub fn SavePlayer::position(self : SavePlayer) -> Array[Double] {
  self.position.copy()
}

///|
pub fn SavePlayer::yaw(self : SavePlayer) -> Double {
  self.yaw
}

///|
pub fn SavePlayer::pitch(self : SavePlayer) -> Double {
  self.pitch
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
) -> Array[@level.BlockDelta] {
  self.block_deltas
}

///|
pub fn SavePayload::encode(self : SavePayload) -> String {
  self.to_json().stringify()
}
