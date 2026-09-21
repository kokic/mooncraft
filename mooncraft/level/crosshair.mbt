///|
pub fn crosshair_block(
  chunk_map~ : @hashmap.HashMap[String, Array[UInt]],
  chunk_size~ : Int,
  player_position~ : Array[Double],
  player_eye_height~ : Double,
  player_yaw~ : Double,
  player_pitch~ : Double,
  raycast_max_distance~ : Double,
) -> @schema.BlockPos? {
  let camera = @camera.camera_from_yaw_pitch(
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
    @schema.AIR_ID,
    false,
  ).map(hit => BlockPos(hit.block[0], hit.block[1], hit.block[2]))
}
