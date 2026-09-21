///|
/// Chat commands and mob navigation hooks.
fn register_command_api(
  game : GameRuntime,
) -> Unit {
  @ffi.cast_global_set("mcExecuteCommand", (input : String) => {
    FlattenResult::from(
      @command.execute_command(
        game.player_runtime,
        game.chunk_runtime,
        game.world,
        game.mob_runtime,
        input,
      ),
    )
  })
  @ffi.cast_global_set("mcRequestZombieNavigation", (
    wx : Int,
    wy : Int,
    wz : Int,
  ) => {
    game.mob_runtime.request_zombie_0_navigation(
      game.chunk_runtime.chunk_map(),
      game.chunk_runtime.chunk_size,
      wx,
      wy,
      wz,
    )
  })
  @ffi.cast_global_set("mcTickEntityRuntime", (
    renderer : @gltf.GltfRenderer,
    delta : Double,
  ) => game.mob_runtime.tick(renderer, delta))
}

///|
pub struct FlattenResult {
  success : Bool
  message : String
}

///|
pub fn FlattenResult::from(result : Result[String, String]) -> FlattenResult {
  match result {
    Ok(msg) => { success: true, message: msg, }
    Err(msg) => { success: false, message: msg, }
  }
}
