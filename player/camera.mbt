///|
pub struct Camera {
  position : Array[Double]
  direction : Array[Double]
  center : Array[Double]
}

///|
/// Build camera basis from position and yaw/pitch.
pub fn camera_from_yaw_pitch(
  position : Array[Double],
  yaw : Double,
  pitch : Double,
) -> Camera {
  let cos_pitch = @math.cos(pitch)
  let dir_x = @math.cos(yaw) * cos_pitch
  let dir_y = @math.sin(pitch)
  let dir_z = @math.sin(yaw) * cos_pitch
  let center = [
    position[0] + dir_x,
    position[1] + dir_y,
    position[2] + dir_z,
  ]
  Camera::{ position, direction: [dir_x, dir_y, dir_z], center }
}
