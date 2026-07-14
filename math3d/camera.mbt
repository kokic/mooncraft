///|
pub let up_vector : Array[Double] = [0.0, 1.0, 0.0]

///|
pub fn camera_from_yaw_pitch_into(
  position : Array[Double],
  direction : Array[Double],
  center : Array[Double],
  px : Double,
  py : Double,
  pz : Double,
  yaw : Double,
  pitch : Double,
) -> Unit {
  let cos_pitch = @math.cos(pitch)
  let dir_x = @math.cos(yaw) * cos_pitch
  let dir_y = @math.sin(pitch)
  let dir_z = @math.sin(yaw) * cos_pitch
  position[0] = px
  position[1] = py
  position[2] = pz
  direction[0] = dir_x
  direction[1] = dir_y
  direction[2] = dir_z
  center[0] = px + dir_x
  center[1] = py + dir_y
  center[2] = pz + dir_z
}
