///|
/// Publish player health, food, breath, and death APIs.
pub fn register_survival_api(game : GameRuntime) -> Unit {
  @ffi.cast_global_set("mcPlayerVitalsSnapshot", () => {
    game.player_runtime.vitals()
  })
  @ffi.cast_global_set("mcApplyPlayerDamage", (amount : Double) => {
    game.player_runtime.apply_damage(amount)
  })
  @ffi.cast_global_set("mcHealPlayer", (amount : Double) => {
    game.player_runtime.heal(amount)
  })
  @ffi.cast_global_set("mcRespawnPlayer", () => { game.player_runtime.respawn() })
}
