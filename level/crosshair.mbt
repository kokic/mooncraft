///|
pub fn crosshair_block(
  // game : @client.GameRuntime,
  // player : PlayerRuntime,
  chunk_map~ : @ffi.JsValue,
  chunk_size~ : Int,
  player_position~ : Array[Double],
  player_eye_height~ : Double,
  player_yaw~ : Double,
  player_pitch~ : Double,
  raycast_max_distance~ : Double,
  // raycast_step~ : Double,
) -> @schema.BlockPos? {
  // let position = player.position()
  let camera = @math3d.camera_from_yaw_pitch(
    [
      player_position[0],
      player_position[1] + player_eye_height,
      player_position[2],
    ],
    player_yaw,
    player_pitch,
  )
  raycast_blocks(
    chunk_map,
    chunk_size,
    camera.position,
    camera.direction,
    raycast_max_distance,
    // raycast_step,
    @schema.AIR_ID,
    false,
  ).map(hit => BlockPos(hit.block[0], hit.block[1], hit.block[2]))
}
