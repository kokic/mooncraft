///|
/// Encode the current world/player/inventory into an explicit save payload.
fn GameRuntime::save_snapshot(self : GameRuntime, saved_at : Double) -> String {
  @save.SavePayload::new(
    saved_at,
    self.world.seed(),
    self.world.world_type_name(),
    self.world.height(),
    self.player_runtime.position(),
    self.player_runtime.yaw(),
    self.player_runtime.pitch(),
    self.player_runtime.velocity_y(),
    self.player_runtime.vitals(),
    self.player_runtime.inventory_snapshot(),
    self.chunk_runtime.block_deltas(),
    self.mob_runtime.save_entities(),
  ).encode()
}

///|
/// Restore full runtime state from a validated save payload.
fn GameRuntime::load_save(
  self : GameRuntime,
  payload : @save.SavePayload,
) -> Unit {
  let saved_player = payload.player()
  ignore(
    self.player_runtime.restore(
      saved_player.position(),
      saved_player.yaw(),
      saved_player.pitch(),
      vitals=Some(saved_player.vitals()),
      velocity_y=saved_player.velocity_y(),
    ),
  )
  ignore(self.player_runtime.restore_inventory(payload.inventory()))
  for delta in payload.block_deltas() {
    self.chunk_runtime.load_block_delta(delta.x, delta.y, delta.z, delta.id)
  }
  self.mob_runtime.restore_entities(payload.entities())
}
