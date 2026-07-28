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
fn register_runtime_api(
  world : @level.World,
  chunk_data : Array[UInt],
  save_text : String,
) -> Unit {
  @mob.reset_entities()
  publish_global("mcCollectHotbarItems", collect_hotbar_items)
  publish_global("mcCollectInventoryItems", collect_inventory_items)
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
  publish_global("mcChunkRuntimeChunkMap", game.chunk_map())
  publish_global("mcTickGame", fn(
    registry : @render.BlockRegistry,
    delta : Double,
  ) {
    game.tick(registry, delta)
  })
  publish_global("mcMarkChunkBlockChanged", fn(wx : Int, wy : Int, wz : Int) {
    game.mark_block_changed(wx, wy, wz)
  })
  publish_global("mcPlayerSnapshot", fn() { game.player_snapshot() })
  publish_global("mcSetPlayerMoveIntent", fn(input : @player.MoveInput) {
    game.set_move_intent(input)
  })
  publish_global("mcAddPlayerLookIntent", fn(yaw : Double, pitch : Double) {
    game.add_look_intent(yaw, pitch)
  })
  publish_global("mcPlayerInventorySnapshot", fn() { game.inventory_snapshot() })
  publish_global("mcSetPlayerGameMode", fn(mode : String) {
    game.set_game_mode(mode)
  })
  publish_global("mcSelectPlayerHotbar", fn(index : Int) {
    game.select_hotbar(index)
  })
  publish_global("mcSetPlayerHotbarSlot", fn(
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
  publish_global("mcSetPlayerInventoryOpen", fn(open : Bool) {
    game.set_inventory_open(open)
  })
  publish_global("mcEncodeGameSave", fn(now : Double) {
    game.save_snapshot(now)
  })
  publish_global("mcExecuteCommand", fn(input : String) {
    game.execute_command(input)
  })
  publish_global("mcRequestZombieNavigation", @mob.request_zombie_0_navigation)
  publish_global("mcTickEntityRuntime", @mob.tick_entity_runtime)
}
