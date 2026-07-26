///|
/// JS bootstrap globals consumed by `dist/js/*`.
/// Keep names stable to avoid breaking JS-side imports.
fn[V] set_global(name : String, value : V) -> Unit {
  @ffi.cast_global_set(name, value)
}

///|
/// Register world type list before world creation (lightweight).
pub fn register_world_types() -> Unit {
  set_global("mcWorldTypes", @level.world_type_names())
  set_global("mcRuntimeReady", true)
}

///|
/// Deferred world creation — JS calls mcLaunchGame after user selects save.
pub fn register_launcher() -> Unit {
  set_global("mcLaunchGame", fn() {
    let seed = @ffi.load_saved_world_seed(@env.now().to_uint())
    let world_type_name = @ffi.load_saved_world_type(
      @ffi.new_world_type("Infinite"),
    )
    let world_type = @level.world_type_from_name(world_type_name)
    let world = @level.World::new(seed~, world_type~)
    let chunk = world.generate_chunk(0, 0, 0)
    register_globals(world, chunk.tile_map)
    @mob.install_default_demo(world)
  })
}

///|
/// Register scalar config and initial world state for JS bootstrap.
fn register_config(world : @level.World) -> Unit {
  // STATUS: COMPLETE - current JS bootstrap contract is centralized here.
  // STATUS: NEEDS_ADJUSTMENT - render distance, update budgets, and debug flags
  // are runtime tuning knobs but are still compiled into this setup path.
  set_global("mcUpdateLabel", "1:10")
  set_global("mcSaveSchemaVersion", @save.SAVE_SCHEMA_VERSION)
  set_global("mcSaveStorageKey", @ffi.active_save_storage_key())
  set_global("mcWorldSeed", world.seed())
  set_global("mcWorldType", world.world_type_name())
  set_global("mcChunkSize", @level.CHUNK_X_SIZE)
  set_global("mcWorldMinY", world.min_y())
  set_global("mcWorldMaxY", world.max_y())
  set_global("mcRenderDistance", @render.CHUNK_RENDER_DISTANCE)
  set_global("mcChunkGenPerFrame", @render.CHUNK_GENERATION_BUDGET)
  set_global("mcMeshBuildPerFrame", @render.CHUNK_MESH_BUDGET)
  set_global("mcChunkSectionSize", @render.CHUNK_SECTION_SIZE)
  set_global("mcDebugChunkGen", false)
  set_global("mcDebugSolid", false)
  set_global("mcUseFixedLight", @level.USE_FIXED_LIGHT)
  set_global("mcFov", 60)
  set_global("mcInventoryGridX", @player.INVENTORY_GRID_X)
  set_global("mcInventoryGridY", @player.INVENTORY_GRID_Y)
  set_global("mcAirLongId", @block.AIR_LONG_ID)
  set_global("mcWaterTintGridStep", 4)
  set_global("mcSpawnChunkX", @player.SPAWN_CHUNK_X)
  set_global("mcSpawnChunkZ", @player.SPAWN_CHUNK_Z)
  set_global("mcSpawnLocalX", @player.SPAWN_LOCAL_X)
  set_global("mcSpawnLocalZ", @player.SPAWN_LOCAL_Z)
  set_global("mcSpawnSurfaceOffset", @player.SPAWN_SURFACE_OFFSET)
  set_global("mcSpawnFallbackY", @player.SPAWN_FALLBACK_Y)
  set_global("mcSpawnYaw", @player.SPAWN_YAW)
  set_global("mcSpawnPitch", @player.SPAWN_PITCH)
  set_global("mcUpVector", @math3d.up_vector)

  // Leaf shader pipeline assets.
  set_global("mcOakLeavesVertexShader", @render.leaf_vertex_shader)
  set_global("mcOakLeavesFragmentShader", @render.leaf_fragment_shader)
  set_global("mcOakLeavesDefaultTint", @genus.default_tint)
}

///|
/// Register JS-callable entry points that forward to MoonBit logic.
fn register_api(world : @level.World, chunk_data : Array[UInt]) -> Unit {
  // STATUS: COMPLETE - this is the intended boundary between MoonBit gameplay
  // logic and the JS renderer/input loop. Keep exported names stable.
  set_global(
    "mcTorchStateFromPlacement",
    @genus.Torch::torch_state_from_placement,
  )
  set_global("mcCollectTextureNames", @block.collect_texture_names)
  set_global("mcCollectBlockLightInfo", @block.collect_block_light_info)
  set_global("mcGetLongIdByName", @block.name_to_long_id)
  set_global("mcCollectHotbarItems", @player.collect_hotbar_items)
  set_global("mcCollectInventoryItems", @player.collect_inventory_items)
  set_global("mcCameraFromYawPitch", @render.camera_from_yaw_pitch)
  set_global("mcCameraFromYawPitchInto", @math3d.camera_from_yaw_pitch_into)
  set_global("mcMat4Create", @render.mat4_create)
  set_global("mcMat4Copy", @render.mat4_copy)
  set_global("mcMat4Perspective", @render.mat4_perspective)
  set_global("mcMat4Ortho", @render.mat4_ortho)
  set_global("mcMat4LookAt", @render.mat4_look_at)
  set_global("mcMat4Mul", @render.mat4_mul)
  set_global("mcMat4FromTRS", @render.mat4_from_trs)
  set_global("mcTransformPoint", @render.transform_point)
  set_global("mcQuatNormalize", @math3d.quat_normalize)
  set_global("mcQuatMul", @math3d.quat_mul)
  set_global("mcQuatApplyYawOffset", @math3d.quat_apply_yaw_offset)
  set_global("mcQuatFromYawPitch", @math3d.quat_from_yaw_pitch)
  set_global("mcQuatSlerp", @math3d.quat_slerp)
  set_global("mcTorchShapeBoxByState", @genus.Torch::shape_box_by_state)
  set_global("mcCreateBlockRegistry", @render.BlockRegistry::create)
  set_global("mcGetRenderBlockByLongId", @render.BlockRegistry::get_by_long_id)
  set_global("mcBlockIsSelectable", @block.Block::is_selectable)
  set_global("mcPackLongId", @util.pack_long_id)
  set_global("mcUnpackLongId", @util.unpack_long_id)
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
  // The chunk map is a zero-copy data bridge; JS reads it, MoonBit owns it.
  set_global("mcChunkRuntimeChunkMap", game.chunk_map())
  // Single per-frame entry point: advance the whole runtime, emit one GameFrame.
  set_global("mcTickGame", fn(
    registry : @render.BlockRegistry,
    delta : Double,
    now : Double,
  ) {
    game.tick(registry, delta, now)
  })
  set_global("mcMarkChunkBlockChanged", fn(wx : Int, wy : Int, wz : Int) {
    game.mark_block_changed(wx, wy, wz)
  })
  set_global("mcPlayerSnapshot", fn() { game.player_snapshot() })
  set_global("mcSetPlayerMoveIntent", fn(input : @player.MoveInput) {
    game.set_move_intent(input)
  })
  set_global("mcAddPlayerLookIntent", fn(yaw : Double, pitch : Double) {
    game.add_look_intent(yaw, pitch)
  })
  set_global("mcPlayerInventorySnapshot", fn() { game.inventory_snapshot() })
  set_global("mcSetPlayerGameMode", fn(mode : String) {
    game.set_game_mode(mode)
  })
  set_global("mcSelectPlayerHotbar", fn(index : Int) {
    game.select_hotbar(index)
  })
  set_global("mcSetPlayerHotbarSlot", fn(
    index : Int,
    name : String,
    category : String,
  ) {
    let slot = if name.length() == 0 {
      None
    } else {
      Some(@player.HotbarSlot::new(name, category))
    }
    game.set_hotbar_slot(index, slot)
  })
  set_global("mcSetPlayerInventoryOpen", fn(open : Bool) {
    game.set_inventory_open(open)
  })
  set_global("mcLoadLevelSave", fn(text : String) {
    match @save.migrate_save_payload(text) {
      Some(payload) if payload.matches_world(
          world.seed(),
          world.world_type_name(),
        ) => {
        game.load_save(payload)
        true
      }
      _ => false
    }
  })
  // Unconditional encode used by JS on unload to guarantee the latest frame.
  set_global("mcFlushGameSave", fn(now : Double) { game.flush_save(now) })
  set_global("mcCanPlaceBlock", @player.can_place_block)
  set_global("mcBuildUiItemMesh", @render.build_ui_item_mesh)
  set_global("mcRaycastBlocks", @level.raycast_blocks)
  set_global("mcGetBlockId", @level.get_block_id)
  set_global("mcIsWaterAt", @level.is_water_at)
  set_global("mcSetBlockId", @level.set_block_id)
  set_global("mcBuildChunkDataPadded", @level.build_chunk_data_padded)
  set_global("mcApplyUseOnAction", @level.apply_use_on_action_with_player)
  set_global("mcApplyUseAction", @level.apply_use_action)
  set_global("mcGetBlockShapeDesc", @block.get_shape_desc)
  set_global("mcComputePlacementState", fn(
    long_id : UInt,
    block : Array[Int],
    prev : Array[Int],
  ) -> UInt {
    @block.compute_placement_state(long_id, block, prev)
  })
  set_global("mcUseItemOn", @item.use_item_on)
  set_global("mcUseItem", @item.use_item)
  set_global("mcGetItemDisplayName", @i18n.item_display_name)
  set_global("mcGetBiomeName", fn(wx : Int, wz : Int) -> String {
    let biome = @biome.biome_at(world.noise, wx, wz)
    @biome.name(biome)
  })
  set_global("mcGetWaterTint", fn(wx : Int, wz : Int) -> Array[Double] {
    let sample = @biome.sample(world.noise, wx, wz)
    let biome = @biome.biome_from_sample(sample)
    let (r, g, b, a) = @genus.Water::tint_for_sample(biome, sample)
    [r.to_double(), g.to_double(), b.to_double(), a.to_double()]
  })
  // GLTF entity rendering pipeline.
  set_global("mcParseGlb", @render.parse_glb)
  set_global("mcReadAccessorValues", @render.read_accessor_values)
  set_global("mcReadIndices", @render.read_indices)
  set_global("mcCreateGltfProgram", @render.create_gltf_program)
  set_global("mcGltfVsSource", @render.GLTF_VS_SOURCE)
  set_global("mcGltfFsSource", @render.GLTF_FS_SOURCE)
  set_global("mcCreateWhiteTexture", @render.create_white_texture)
  set_global("mcCreateTextureFromImage", @render.create_texture_from_image)
  set_global("mcBuildGltfPrimitive", @render.build_gltf_primitive)
  set_global("mcDisposeGltfPrimitives", @render.dispose_gltf_primitives)
  set_global("mcCreateGltfRenderer", @render.create_gltf_renderer)
  set_global("mcUpdateGltfRenderer", @render.update_gltf_renderer)
  set_global("mcRenderGltfRenderer", @render.render_gltf_renderer)
  set_global("mcGltfSetAnimation", @render.gltf_set_animation)
  set_global("mcGltfSetTexture", @render.gltf_set_texture)
  set_global("mcGltfSetRotation", @render.gltf_set_rotation)
  set_global("mcGltfSetYaw", @render.gltf_set_yaw)
  set_global("mcGltfSetScale", @render.gltf_set_scale)
  set_global("mcGltfLookAtXz", @render.gltf_look_at_xz)
  set_global("mcGltfLookAtXyz", @render.gltf_look_at_xyz)
  set_global("mcGltfEntityIds", @render.gltf_entity_ids)
  set_global("mcGltfEntityCount", @render.gltf_entity_count)
  set_global("mcRequestZombieNavigation", @mob.request_zombie_0_navigation)
  set_global("mcTickEntityRuntime", @mob.tick_entity_runtime)
}

///|
/// Main entry: register all JS globals.
fn register_globals(world : @level.World, chunk_data : Array[UInt]) -> Unit {
  register_config(world)
  register_api(world, chunk_data)
}
