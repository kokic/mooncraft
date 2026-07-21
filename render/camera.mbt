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
  let direction = [0.0, 0.0, 0.0]
  let center = [0.0, 0.0, 0.0]
  @math3d.camera_from_yaw_pitch_into(
    position,
    direction,
    center,
    position[0],
    position[1],
    position[2],
    yaw,
    pitch,
  )
  { position, direction, center }
}
