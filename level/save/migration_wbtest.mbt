///|
test "migrate legacy level save into current schema" {
  let legacy =
    #|{
    #|  "version": 1,
    #|  "savedAt": 42,
    #|  "world": { "seed": 7, "worldType": "Infinite" },
    #|  "runtime": {
    #|    "player": { "position": [1, 2, 3], "yaw": 0.5, "pitch": -0.25 },
    #|    "gameMode": "survival",
    #|    "hotbar": {
    #|      "selectedIndex": 2,
    #|      "items": [{ "name": "stone", "category": "block" }]
    #|    },
    #|    "ui": { "inventoryOpen": true }
    #|  },
    #|  "blockDeltas": [{ "wx": 4, "wy": 5, "wz": 6, "id": 9 }]
    #|}
  guard migrate_save_payload(legacy) is Some(payload) else {
    fail("expected migrated level save")
  }
  assert_eq(payload.version, SAVE_SCHEMA_VERSION)
  assert_eq(payload.world.seed, 7U)
  assert_eq(payload.world.world_type, "Infinite")
  assert_eq(payload.player.position, [1.0, 2.0, 3.0])
  assert_eq(payload.inventory.game_mode, "survival")
  assert_eq(payload.inventory.selected_hotbar_index, 2)
  assert_true(payload.inventory.inventory_open)
  assert_eq(payload.block_deltas.length(), 1)
  assert_eq(payload.block_deltas[0].x, 4)
}

///|
test "current level save encodes canonical snake case fields" {
  let inventory = @player.PlayerInventoryRuntime::new().snapshot()
  let payload = SavePayload::new(
    100.0,
    12U,
    "Flat",
    [1.0, 2.0, 3.0],
    0.0,
    0.0,
    inventory,
    [],
  )
  let encoded = payload.encode()
  assert_true(encoded.contains("\"world_type\""))
  assert_true(encoded.contains("\"block_deltas\""))
  assert_false(encoded.contains("\"worldType\""))
}

///|
test "reject malformed and unsupported level saves" {
  let malformed =
    #|{
    #|  "version": 1,
    #|  "savedAt": 42,
    #|  "world": { "seed": "not-a-seed", "worldType": "Infinite" }
    #|}
  assert_true(migrate_save_payload(malformed) is None)
  assert_true(migrate_save_payload("{\"version\":99}") is None)
}
