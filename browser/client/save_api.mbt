///|
/// Restore the runtime only when the serialized state belongs to this world.
fn load_initial_save(
  game : GameRuntime,
  save_text : String,
) -> Unit {
  guard !save_text.is_empty() else { () }
  guard @save.decode_save_payload(save_text) is Some(payload) else { () }
  guard payload.matches_world(
    game.world.seed(),
    game.world.world_type_name(),
    game.world.height(),
  ) else {
    ()
  }
  game.load_save(payload)
}

///|
/// Save-slot integration for play sessions.
fn register_save_api(game : GameRuntime) -> Unit {
  @ffi.cast_global_set("mcEncodeGameSave", (now : Double) => {
    game.save_snapshot(now)
  })
}
