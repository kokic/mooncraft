///|
fn approx(actual : Double, expected : Double) -> Bool {
  (actual - expected).abs() <= 0.00001
}

///|
test "matrix creation, copy, TRS, multiplication and point transform" {
  let identity = @math3d.mat4_create()
  assert_true(approx(identity.at(0), 1.0))
  assert_true(approx(identity.at(5), 1.0))
  assert_true(approx(identity.at(10), 1.0))
  assert_true(approx(identity.at(15), 1.0))
  let model = @math3d.mat4_create()
  ignore(
    @math3d.mat4_from_trs(model, [2.0, 3.0, 4.0], [0.0, 0.0, 0.0, 1.0], [
      1.0, 1.0, 1.0,
    ]),
  )
  let copied = @math3d.mat4_create()
  ignore(@math3d.mat4_copy(copied, model))
  let multiplied = @math3d.mat4_create()
  ignore(@math3d.mat4_mul(multiplied, identity, copied))
  let point = [0.0, 0.0, 0.0]
  ignore(@math3d.transform_point(point, multiplied, [1.0, 2.0, 3.0]))
  assert_true(approx(point[0], 3.0))
  assert_true(approx(point[1], 5.0))
  assert_true(approx(point[2], 7.0))
}

///|
test "projection and look-at matrices" {
  let perspective = @math3d.mat4_create()
  ignore(@math3d.mat4_perspective(perspective, @math.PI / 2.0, 1.0, 0.1, 100.0))
  assert_true(approx(perspective.at(0), 1.0))
  assert_true(approx(perspective.at(5), 1.0))
  assert_true(approx(perspective.at(11), -1.0))
  let ortho = @math3d.mat4_create()
  ignore(@math3d.mat4_ortho(ortho, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0))
  assert_true(approx(ortho.at(0), 1.0))
  assert_true(approx(ortho.at(5), 1.0))
  assert_true(approx(ortho.at(10), -1.0))
  let view = @math3d.mat4_create()
  ignore(
    @math3d.mat4_look_at(view, [0.0, 0.0, 1.0], [0.0, 0.0, 0.0], [0.0, 1.0, 0.0]),
  )
  assert_true(approx(view.at(0), 1.0))
  assert_true(approx(view.at(5), 1.0))
  assert_true(approx(view.at(10), 1.0))
  assert_true(approx(view.at(14), -1.0))
}

///|
test "camera and quaternion operations" {
  let position = [0.0, 0.0, 0.0]
  let direction = [0.0, 0.0, 0.0]
  let center = [0.0, 0.0, 0.0]
  @math3d.camera_from_yaw_pitch_into(
    position, direction, center, 1.0, 2.0, 3.0, 0.0, 0.0,
  )
  assert_true(approx(direction[0], 1.0))
  assert_true(approx(direction[1], 0.0))
  assert_true(approx(direction[2], 0.0))
  assert_true(approx(center[0], 2.0))
  let normalized = [0.0, 0.0, 0.0, 0.0]
  ignore(@math3d.quat_normalize(normalized, normalized))
  assert_true(approx(normalized[3], 1.0))
  let yaw_pitch = [0.0, 0.0, 0.0, 1.0]
  ignore(@math3d.quat_from_yaw_pitch(yaw_pitch, 0.7, -0.2))
  let length = (yaw_pitch[0] * yaw_pitch[0] +
  yaw_pitch[1] * yaw_pitch[1] +
  yaw_pitch[2] * yaw_pitch[2] +
  yaw_pitch[3] * yaw_pitch[3]).sqrt()
  assert_true(approx(length, 1.0))
  let mid = [0.0, 0.0, 0.0, 1.0]
  ignore(
    @math3d.quat_slerp(mid, [0.0, 0.0, 0.0, 1.0], [0.0, 1.0, 0.0, 0.0], 0.5),
  )
  assert_true(approx(mid[1], 2.0.sqrt() / 2.0))
  assert_true(approx(mid[3], 2.0.sqrt() / 2.0))
}
