///|
test "profile raycast uses cactus bounds" {
  let cactus = lookup_by_name("cactus").unwrap().long_id()
  let origin = [0.0, 0.5, 0.5]
  let direction = [1.0, 0.0, 0.0]
  @test.assert_eq(
    raycast_intersects(cactus, origin, direction, 0, 0, 0, false),
    true,
  )

  let misses_cactus = raycast_intersects(
    cactus,
    [0.0, 0.5, 0.01],
    direction,
    0,
    0,
    0,
    false,
  )
  @test.assert_eq(misses_cactus, false)
}

///|
test "profile raycast preserves liquid opt-in" {
  let water = lookup_by_name("water").unwrap().long_id()
  let origin = [0.5, 0.5, -1.0]
  let direction = [0.0, 0.0, 1.0]
  @test.assert_eq(
    raycast_intersects(water, origin, direction, 0, 0, 0, false),
    false,
  )
  @test.assert_eq(
    raycast_intersects(water, origin, direction, 0, 0, 0, true),
    true,
  )
}

///|
test "profile placement preserves torch state" {
  let torch = lookup_by_name("torch").unwrap().long_id()
  let state = compute_placement_state(torch, [0, 0, 0], [0, 0, 1])
  @test.assert_eq(state, 1U)
}

///|
test "profile outline uses cactus bounds" {
  let cactus = lookup_by_name("cactus").unwrap().long_id()
  let box = get_outline_desc(cactus).unwrap().boxes[0]
  @test.assert_eq(box.min[0], 0.0625F)
  @test.assert_eq(box.max[0], 0.9375F)
}
