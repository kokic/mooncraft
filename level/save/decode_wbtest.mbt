///|
test "current level save encodes world height" {
  let inventory = @player.PlayerInventoryRuntime::new().snapshot()
  let payload = SavePayload::new(
    100.0,
    12U,
    "Infinite",
    192,
    [1.0, 2.0, 3.0],
    0.0,
    0.0,
    inventory,
    [],
  )
  let encoded = payload.encode()
  assert_true(encoded.contains("\"world_type\""))
  assert_true(encoded.contains("\"height\":192"))
  guard decode_save_payload(encoded) is Some(decoded) else {
    fail("expected current level save")
  }
  @test.assert_eq(decoded.world.height, 192)
}

///|
test "save payload requires a matching world height" {
  let inventory = @player.PlayerInventoryRuntime::new().snapshot()
  let payload = SavePayload::new(
    100.0,
    12U,
    "Infinite",
    192,
    [1.0, 2.0, 3.0],
    0.0,
    0.0,
    inventory,
    [],
  )
  @test.assert_eq(payload.matches_world(12U, "Infinite", 192), true)
  @test.assert_eq(payload.matches_world(12U, "Infinite", 384), false)
}

///|
test "reject legacy, malformed, and unsupported level saves" {
  let legacy =
    #|{
    #|  "version": 2,
    #|  "saved_at": 42,
    #|  "world": { "seed": 7, "world_type": "Infinite" }
    #|}
  @test.assert_eq(decode_save_payload(legacy) is None, true)
  @test.assert_eq(decode_save_payload("{\"version\":99}") is None, true)
  @test.assert_eq(decode_save_payload("not json") is None, true)
}
