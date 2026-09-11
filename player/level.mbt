///|
pub const PLAYER_EYE_HEIGHT : Double = 1.65

///|
pub const DEFAULT_RAYCAST_MAX_DISTANCE : Double = 10.0

///|
pub const DEFAULT_RAYCAST_STEP : Double = 0.05

///|
pub fn PlayerRuntime::crosshair_block(
  player : PlayerRuntime,
  chunk_map~ : @hashmap.HashMap[String, Array[UInt]],
  chunk_size~ : Int,
  // player_position~ : Array[Double],
  player_eye_height? : Double = PLAYER_EYE_HEIGHT,
  // player_yaw~ : Double,
  // player_pitch~ : Double,
  raycast_max_distance? : Double = DEFAULT_RAYCAST_MAX_DISTANCE,
) -> @schema.BlockPos? {
  @level.crosshair_block(
    chunk_map~,
    chunk_size~,
    player_position=player.position(),
    player_eye_height~,
    player_yaw=player.yaw(),
    player_pitch=player.pitch(),
    raycast_max_distance~,
  )
}
