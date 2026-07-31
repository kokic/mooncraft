///|
fn matrix_approx(actual : Double, expected : Double) -> Bool {
  (actual - expected).abs() <= 0.00001
}

///|
test "matrix creation, copy, TRS, multiplication and point transform" {
  let identity = mat4_create()
  assert_true(matrix_approx(identity.at(0), 1.0))
  assert_true(matrix_approx(identity.at(5), 1.0))
  assert_true(matrix_approx(identity.at(10), 1.0))
  assert_true(matrix_approx(identity.at(15), 1.0))
  let model = mat4_create()
  ignore(
    mat4_from_trs(model, [2.0, 3.0, 4.0], [0.0, 0.0, 0.0, 1.0], [1.0, 1.0, 1.0]),
  )
  let copied = mat4_create()
  ignore(mat4_copy(copied, model))
  let multiplied = mat4_create()
  ignore(mat4_mul(multiplied, identity, copied))
  let point = [0.0, 0.0, 0.0]
  ignore(transform_point(point, multiplied, [1.0, 2.0, 3.0]))
  assert_true(matrix_approx(point[0], 3.0))
  assert_true(matrix_approx(point[1], 5.0))
  assert_true(matrix_approx(point[2], 7.0))
}

///|
test "projection and look-at matrices" {
  let perspective = mat4_create()
  ignore(mat4_perspective(perspective, @math.PI / 2.0, 1.0, 0.1, 100.0))
  assert_true(matrix_approx(perspective.at(0), 1.0))
  assert_true(matrix_approx(perspective.at(5), 1.0))
  assert_true(matrix_approx(perspective.at(11), -1.0))
  let ortho = mat4_create()
  ignore(mat4_ortho(ortho, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0))
  assert_true(matrix_approx(ortho.at(0), 1.0))
  assert_true(matrix_approx(ortho.at(5), 1.0))
  assert_true(matrix_approx(ortho.at(10), -1.0))
  let view = mat4_create()
  ignore(mat4_look_at(view, [0.0, 0.0, 1.0], [0.0, 0.0, 0.0], [0.0, 1.0, 0.0]))
  assert_true(matrix_approx(view.at(0), 1.0))
  assert_true(matrix_approx(view.at(5), 1.0))
  assert_true(matrix_approx(view.at(10), 1.0))
  assert_true(matrix_approx(view.at(14), -1.0))
}
