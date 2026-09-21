///|
/// How the game client is launched.
///
/// `Play` runs a full session (demo entities, save-slot integration).
/// `Design` runs the developer-only Design world: an empty canvas with
/// blueprint-only persistence.
pub(all) enum LaunchMode {
  Play
  Design
}

///|
/// Create the authoritative CPU-side runtime and publish its stateful API.
pub fn register_runtime_api(
  world : @level.World,
  chunk_data : Array[UInt],
  save_text : String,
  mob_runtime : @mob.MobRuntime,
  mode : LaunchMode,
) -> Unit {
  let game = GameRuntime::new(world, chunk_data, mob_runtime)
  load_initial_save(game, save_text)
  register_world_api(game)
  register_player_api(game)
  register_survival_api(game)
  register_game_tick_api(game)
  match mode {
    LaunchMode::Play => register_save_api(game)
    LaunchMode::Design => ()
  }
  register_command_api(game)
  register_designer_api(game)
}

///|
/// Per-frame game simulation and block-change bookkeeping.
fn register_game_tick_api(game : GameRuntime) -> Unit {
  @ffi.cast_global_set("mcTickGame", (
    registry : @block.RenderRegistry,
    delta : Double,
  ) => {
    game.tick(registry, delta)
  })
  @ffi.cast_global_set("mcMarkChunkBlockChanged", (
    wx : Int,
    wy : Int,
    wz : Int,
  ) => {
    game.chunk_runtime.mark_block_changed(wx, wy, wz)
  })
}
