///|
/// Restore the runtime only when the serialized state belongs to this world.
fn load_initial_save(
  game : GameRuntime,
  world : @level.World,
  save_text : String,
) -> Unit {
  guard !save_text.is_empty() else { () }
  guard @save.decode_save_payload(save_text) is Some(payload) else { () }
  guard payload.matches_world(
    world.seed(),
    world.world_type_name(),
    world.height(),
  ) else {
    ()
  }
  game.load_save(payload)
}

///|
/// Create the authoritative CPU-side runtime and publish its stateful API.
pub fn register_runtime_api(
  world : @level.World,
  chunk_data : Array[UInt],
  save_text : String,
) -> Unit {
  @mob.reset_entities()
  @ffi.cast_global_set("mcCollectHotbarItems", collect_hotbar_items)
  @ffi.cast_global_set("mcCollectInventoryItems", collect_inventory_items)
  let chunk_runtime = @render.ChunkRuntime::new(
    world,
    chunk_data,
    spawn_chunk_x=@player.SPAWN_CHUNK_X,
    spawn_chunk_z=@player.SPAWN_CHUNK_Z,
  )
  let spawn = @player.compute_spawn_position(
    chunk_runtime.chunk_map(),
    @level.CHUNK_X_SIZE,
    @util.floor_div(world.min_y(), @level.CHUNK_X_SIZE),
    @util.floor_div(world.max_y(), @level.CHUNK_X_SIZE),
    @player.SPAWN_CHUNK_X,
    @player.SPAWN_CHUNK_Z,
    @player.SPAWN_LOCAL_X,
    @player.SPAWN_LOCAL_Z,
    @player.SPAWN_SURFACE_OFFSET,
    @player.SPAWN_FALLBACK_Y,
  )
  let player_runtime = @player.PlayerRuntime::new(
    chunk_runtime.chunk_map(),
    @level.CHUNK_X_SIZE,
    world.min_y(),
    @player.PlayerInventoryRuntime::new(),
    spawn.position,
    @player.SPAWN_YAW,
    @player.SPAWN_PITCH,
  )
  let game = GameRuntime::new(
    world,
    chunk_runtime,
    player_runtime,
    @level.CHUNK_X_SIZE,
  )
  load_initial_save(game, world, save_text)
  @ffi.cast_global_set("mcChunkRuntimeChunkMap", game.chunk_map())
  @ffi.cast_global_set("mcTickGame", fn(
    registry : @render.BlockRegistry,
    delta : Double,
  ) {
    game.tick(registry, delta)
  })
  @ffi.cast_global_set("mcMarkChunkBlockChanged", fn(wx : Int, wy : Int, wz : Int) {
    game.mark_block_changed(wx, wy, wz)
  })
  @ffi.cast_global_set("mcPlayerSnapshot", fn() { game.player_snapshot() })
  @ffi.cast_global_set("mcSetPlayerMoveIntent", fn(input : @player.MoveInput) {
    game.set_move_intent(input)
  })
  @ffi.cast_global_set("mcAddPlayerLookIntent", fn(yaw : Double, pitch : Double) {
    game.add_look_intent(yaw, pitch)
  })
  @ffi.cast_global_set("mcPlayerInventorySnapshot", fn() { game.inventory_snapshot() })
  @ffi.cast_global_set("mcSetPlayerGameMode", fn(mode : String) {
    game.set_game_mode(mode)
  })
  @ffi.cast_global_set("mcSelectPlayerHotbar", fn(index : Int) {
    game.select_hotbar(index)
  })
  @ffi.cast_global_set("mcSetPlayerHotbarSlot", fn(
    index : Int,
    name : String,
    category : String,
  ) {
    let slot = if name.is_empty() {
      None
    } else {
      Some(@player.HotbarSlot::new(name, category))
    }
    game.set_hotbar_slot(index, slot)
  })
  @ffi.cast_global_set("mcSetPlayerInventoryOpen", fn(open : Bool) {
    game.set_inventory_open(open)
  })
  @ffi.cast_global_set("mcEncodeGameSave", fn(now : Double) {
    game.save_snapshot(now)
  })
  @ffi.cast_global_set("mcExecuteCommand", fn(input : String) {
    game.execute_command(input)
  })
  @ffi.cast_global_set("mcRequestZombieNavigation", @mob.request_zombie_0_navigation)
  @ffi.cast_global_set("mcTickEntityRuntime", @mob.tick_entity_runtime)
}
