///|
/// Apply a use action, routing player-affecting actions (eating) away from the
/// world. Returns the chunk keys that need remeshing.
fn GameRuntime::apply_use_action(
  self : GameRuntime,
  action : @item.UseAction,
) -> Array[String] {
  match action {
    @item.UseAction::Eat(nutrition~, saturation~) => {
      ignore(self.player_runtime.eat(nutrition, saturation))
      []
    }
    _ =>
      @level.apply_use_action(
        self.chunk_runtime.chunk_map(),
        self.chunk_size,
        action,
      )
  }
}

///|
/// Publish player health, food, breath, and death APIs.
pub fn register_survival_api(game : GameRuntime) -> Unit {
  @ffi.cast_global_set("mcPlayerVitalsSnapshot", fn() {
    game.player_runtime.vitals()
  })
  @ffi.cast_global_set("mcApplyPlayerDamage", fn(amount : Double) {
    game.player_runtime.apply_damage(amount)
  })
  @ffi.cast_global_set("mcHealPlayer", fn(amount : Double) {
    game.player_runtime.heal(amount)
  })
  @ffi.cast_global_set("mcRespawnPlayer", fn() { game.player_runtime.respawn() })
}
