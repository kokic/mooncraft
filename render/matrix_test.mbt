///|
fn approx(actual : Double, expected : Double) -> Bool {
  (actual - expected).abs() <= 0.00001
}

///|
test "matrix creation, copy, TRS, multiplication and point transform" {
  let identity = @render.mat4_create()
  assert_true(approx(identity.at(0), 1.0))
  assert_true(approx(identity.at(5), 1.0))
  assert_true(approx(identity.at(10), 1.0))
  assert_true(approx(identity.at(15), 1.0))
  let model = @render.mat4_create()
  ignore(
    @render.mat4_from_trs(model, [2.0, 3.0, 4.0], [0.0, 0.0, 0.0, 1.0], [
      1.0, 1.0, 1.0,
    ]),
  )
  let copied = @render.mat4_create()
  ignore(@render.mat4_copy(copied, model))
  let multiplied = @render.mat4_create()
  ignore(@render.mat4_mul(multiplied, identity, copied))
  let point = [0.0, 0.0, 0.0]
  ignore(@render.transform_point(point, multiplied, [1.0, 2.0, 3.0]))
  assert_true(approx(point[0], 3.0))
  assert_true(approx(point[1], 5.0))
  assert_true(approx(point[2], 7.0))
}

///|
test "projection and look-at matrices" {
  let perspective = @render.mat4_create()
  ignore(@render.mat4_perspective(perspective, @math.PI / 2.0, 1.0, 0.1, 100.0))
  assert_true(approx(perspective.at(0), 1.0))
  assert_true(approx(perspective.at(5), 1.0))
  assert_true(approx(perspective.at(11), -1.0))
  let ortho = @render.mat4_create()
  ignore(@render.mat4_ortho(ortho, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0))
  assert_true(approx(ortho.at(0), 1.0))
  assert_true(approx(ortho.at(5), 1.0))
  assert_true(approx(ortho.at(10), -1.0))
  let view = @render.mat4_create()
  ignore(
    @render.mat4_look_at(view, [0.0, 0.0, 1.0], [0.0, 0.0, 0.0], [0.0, 1.0, 0.0]),
  )
  assert_true(approx(view.at(0), 1.0))
  assert_true(approx(view.at(5), 1.0))
  assert_true(approx(view.at(10), 1.0))
  assert_true(approx(view.at(14), -1.0))
}
