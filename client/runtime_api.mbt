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
/// Build browser UI views from the canonical player hotbar definition.
fn collect_hotbar_items() -> Array[@ui.UiItemView] {
  @player.hotbar_blocks.map(@ui.block_to_ui_item)
}

///|
/// Build inventory UI views from the canonical block and item registries.
fn collect_inventory_items() -> Array[@ui.UiItemView] {
  [
    ..@block.blocks
    .filter(block => block.category != @item.None)
    .map(@ui.block_to_ui_item),

    //
    ..@item.items
    .filter(item => item.category != @item.None)
    .map(@ui.item_to_ui_item),
  ]
}

///|
/// Create the authoritative CPU-side runtime and publish its stateful API.
pub fn register_runtime_api(
  world : @level.World,
  chunk_data : Array[UInt],
  save_text : String,
  mob_runtime : @mob.MobRuntime,
  designer : Bool,
) -> Unit {
  @ffi.cast_global_set("mcCollectHotbarItems", collect_hotbar_items)
  @ffi.cast_global_set("mcCollectInventoryItems", collect_inventory_items)
  let chunk_runtime = @chunk.ChunkRuntime::new(
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
    mob_runtime,
    @level.CHUNK_X_SIZE,
  )
  load_initial_save(game, world, save_text)
  @ffi.cast_global_set("mcGetBlockId", (wx : Int, wy : Int, wz : Int) => {
    @level.get_block_id(
      game.chunk_runtime.chunk_map(),
      game.chunk_size,
      wx,
      wy,
      wz,
    )
  })
  @ffi.cast_global_set("mcSetBlockId", (wx : Int, wy : Int, wz : Int, id : UInt) => {
    @level.set_block_id(
      game.chunk_runtime.chunk_map(),
      game.chunk_size,
      wx,
      wy,
      wz,
      id,
    )
  })
  @ffi.cast_global_set("mcIsWaterAt", (wx : Int, wy : Int, wz : Int) => {
    @level.is_water_at(
      game.chunk_runtime.chunk_map(),
      game.chunk_size,
      wx,
      wy,
      wz,
    )
  })
  @ffi.cast_global_set("mcRaycastBlocks", (
    origin : Array[Double],
    dir : Array[Double],
    max_dist : Double,
    air_id : UInt,
    include_liquid_hit : Bool,
  ) => {
    @level.raycast_blocks(
      game.chunk_runtime.chunk_map(),
      game.chunk_size,
      origin,
      dir,
      max_dist,
      air_id,
      include_liquid_hit,
    )
  })
  @ffi.cast_global_set("mcApplyUseAction", (action : @item.UseAction) => {
    @level.apply_use_action(
      game.chunk_runtime.chunk_map(),
      game.chunk_size,
      action,
    )
  })
  @ffi.cast_global_set("mcApplyUseOnAction", (
    action : @item.UseOnAction,
    player_pos : Array[Double],
    entity_height : Double,
    entity_radius : Double,
  ) => {
    @level.apply_use_on_action_with_player(
      game.chunk_runtime.chunk_map(),
      game.chunk_size,
      action,
      player_pos,
      entity_height,
      entity_radius,
    )
  })
  @ffi.cast_global_set("mcTickGame", fn(
    registry : @block.RenderRegistry,
    delta : Double,
  ) {
    game.tick(registry, delta)
  })
  @ffi.cast_global_set("mcMarkChunkBlockChanged", fn(
    wx : Int,
    wy : Int,
    wz : Int,
  ) {
    game.mark_block_changed(wx, wy, wz)
  })
  @ffi.cast_global_set("mcPlayerSnapshot", fn() { game.player_snapshot() })
  @ffi.cast_global_set("mcSetPlayerMoveIntent", fn(input : @player.MoveInput) {
    game.set_move_intent(input)
  })
  @ffi.cast_global_set("mcAddPlayerLookIntent", fn(
    yaw : Double,
    pitch : Double,
  ) {
    game.add_look_intent(yaw, pitch)
  })
  @ffi.cast_global_set("mcPlayerInventorySnapshot", fn() {
    game.inventory_snapshot()
  })
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
    let slot = {
      guard name.is_empty() else { None }
      Some(@player.HotbarSlot::new(name, category))
    }
    game.set_hotbar_slot(index, slot)
  })
  @ffi.cast_global_set("mcSetPlayerInventoryOpen", (open : Bool) => {
    game.set_inventory_open(open)
  })
  if !designer {
    @ffi.cast_global_set("mcEncodeGameSave", (now : Double) => {
      game.save_snapshot(now)
    })
  }
  @ffi.cast_global_set("mcExecuteCommand", (input : String) => {
    FlattenResult::from(
      @command.execute_command(
        game.player_runtime,
        game.chunk_runtime,
        game.world,
        mob_runtime,
        input,
      ),
    )
  })
  @ffi.cast_global_set("mcRequestZombieNavigation", (
    wx : Int,
    wy : Int,
    wz : Int,
  ) => {
    mob_runtime.request_zombie_0_navigation(
      game.chunk_runtime.chunk_map(),
      game.chunk_size,
      wx,
      wy,
      wz,
    )
  })
  @ffi.cast_global_set("mcTickEntityRuntime", (
    renderer : @gltf.GltfRenderer,
    delta : Double,
  ) => mob_runtime.tick(renderer, delta))
  register_designer_api(game)
}

///|
pub struct FlattenResult {
  success : Bool
  message : String
}

///|
pub fn FlattenResult::from(result : Result[String, String]) -> FlattenResult {
  match result {
    Ok(msg) => { success: true, message: msg }
    Err(msg) => { success: false, message: msg }
  }
}
