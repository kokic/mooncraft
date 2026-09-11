///|
fn approx(actual : Double, expected : Double) -> Bool {
  (actual - expected).abs() <= 0.00001
}

///|
test "camera and quaternion operations" {
  let position = [0.0, 0.0, 0.0]
  let direction = [0.0, 0.0, 0.0]
  let center = [0.0, 0.0, 0.0]
  @camera.camera_from_yaw_pitch_into(
    position, direction, center, 1.0, 2.0, 3.0, 0.0, 0.0,
  )
  assert_true(approx(direction[0], 1.0))
  assert_true(approx(direction[1], 0.0))
  assert_true(approx(direction[2], 0.0))
  assert_true(approx(center[0], 2.0))
  let normalized = [0.0, 0.0, 0.0, 0.0]
  ignore(@camera.quat_normalize(normalized, normalized))
  assert_true(approx(normalized[3], 1.0))
  let yaw_pitch = [0.0, 0.0, 0.0, 1.0]
  ignore(@camera.quat_from_yaw_pitch(yaw_pitch, 0.7, -0.2))
  let length = (yaw_pitch[0] * yaw_pitch[0] +
  yaw_pitch[1] * yaw_pitch[1] +
  yaw_pitch[2] * yaw_pitch[2] +
  yaw_pitch[3] * yaw_pitch[3]).sqrt()
  assert_true(approx(length, 1.0))
  let mid = [0.0, 0.0, 0.0, 1.0]
  ignore(
    @camera.quat_slerp(mid, [0.0, 0.0, 0.0, 1.0], [0.0, 1.0, 0.0, 0.0], 0.5),
  )
  assert_true(approx(mid[1], 2.0.sqrt() / 2.0))
  assert_true(approx(mid[3], 2.0.sqrt() / 2.0))
}
