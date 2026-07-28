///|
test "entity movement interpolates and completes" {
  let runtime = EntityRuntime::new()
  assert_true(
    runtime.spawn(
      EntitySpawn::new(
        "zombie",
        Mob(Zombie),
        0.0,
        1.0,
        0.0,
        1.35,
        2.0,
        @math.PI * 4.0,
      ),
    ),
  )
  assert_true(runtime.set_path("zombie", [EntityPosition::new(2.0, 1.0, 0.0)]))
  ignore(runtime.tick(0.5))
  guard runtime.position("zombie") is Some(position) else {
    fail("missing entity")
  }
  assert_true((position.x - 1.0).abs() < 0.000001)
  ignore(runtime.tick(0.5))
  guard runtime.position("zombie") is Some(position) else {
    fail("missing entity")
  }
  assert_true((position.x - 2.0).abs() < 0.000001)
}

///|
test "entity tick emits one start event and turns toward movement" {
  let runtime = EntityRuntime::new()
  assert_true(
    runtime.spawn(
      EntitySpawn::new(
        "zombie",
        Mob(Zombie),
        0.0,
        1.0,
        0.0,
        1.35,
        1.0,
        @math.PI * 4.0,
      ),
    ),
  )
  assert_true(runtime.set_path("zombie", [EntityPosition::new(0.0, 1.0, 2.0)]))
  guard runtime.tick(0.1) is [MovementStarted("zombie")] else {
    fail("expected movement start")
  }
  guard runtime.snapshots() is [snapshot] else { fail("expected one entity") }
  assert_true(snapshot.yaw > 0.0)
  assert_true((snapshot.position.z - 0.1).abs() < 0.000001)
  guard runtime.tick(0.1) is [] else { fail("movement start must not repeat") }
}
