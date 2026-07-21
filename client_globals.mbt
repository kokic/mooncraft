///|
/// JS bootstrap globals consumed by `dist/js/*`.
/// Keep names stable to avoid breaking JS-side imports.
fn[V] set_global(name : String, value : V) -> Unit {
  @ffi.cast_global_set(name, value)
}

///|
/// Register scalar config and initial world state for JS bootstrap.
fn register_config(world : @level.World, chunk_data : Array[UInt]) -> Unit {
  // STATUS: COMPLETE - current JS bootstrap contract is centralized here.
  // STATUS: NEEDS_ADJUSTMENT - render distance, update budgets, and debug flags
  // are runtime tuning knobs but are still compiled into this setup path.
  set_global("mcUpdateLabel", "1:10")
  set_global("mcSaveSchemaVersion", 1)
  set_global("mcSaveStorageKey", @ffi.active_save_storage_key())
  set_global("mcWorldSeed", world.seed())
  set_global("mcWorldType", world.world_type_name())
  set_global("mcChunkSize", @level.CHUNK_X_SIZE)
  set_global("mcChunkData", chunk_data)
  set_global("mcWorldMinY", world.min_y())
  set_global("mcWorldMaxY", world.max_y())
  set_global("mcRenderDistance", 2)
  set_global("mcChunkGenPerFrame", 2)
  set_global("mcMeshBuildPerFrame", 2)
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
  set_global("mcUpVector", @math3d.up_vector)

  // Leaf shader pipeline assets.
  set_global("mcOakLeavesVertexShader", @render.leaf_vertex_shader)
  set_global("mcOakLeavesFragmentShader", @render.leaf_fragment_shader)
  set_global("mcOakLeavesDefaultTint", @genus.default_tint)
}

///|
/// Register JS-callable entry points that forward to MoonBit logic.
fn register_api(world : @level.World) -> Unit {
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
  set_global("mcComputeSpawnPosition", @player.compute_spawn_position)
  set_global("mcTorchShapeBoxByState", @genus.Torch::shape_box_by_state)
  set_global("mcCreateBlockRegistry", @render.BlockRegistry::create)
  set_global("mcGetRenderBlockByLongId", @render.BlockRegistry::get_by_long_id)
  set_global("mcBlockIsSelectable", @block.Block::is_selectable)
  set_global("mcPackLongId", @util.pack_long_id)
  set_global("mcUnpackLongId", @util.unpack_long_id)
  set_global("mcChunkXyzByKey", @level.chunk_xyz_by_chunk_key)
  set_global("mcCollectRenderChunkKeys", @render.collect_render_chunk_keys)
  set_global("mcCanPlaceBlock", @player.can_place_block)
  set_global("mcBuildChunkMesh", @render.build_chunk_mesh)
  set_global("mcBuildChunkColors", @render.build_chunk_colors)
  set_global("mcBuildChunkColorsSplit", @render.build_chunk_colors_split)
  set_global("mcBuildWorldMesh", @render.build_world_mesh)
  set_global("mcBuildWorldMeshSplit", @render.build_world_mesh_split)
  set_global("mcBuildWorldLight", @level.build_world_light)
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
  set_global("mcMovePlayer", @player.move_player)
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
  let gen_chunk = fn(x : Int, y : Int, z : Int) -> Array[UInt] {
    world.generate_chunk(x, y, z).tile_map
  }
  set_global("mcGenChunk", gen_chunk)
}

///|
/// Main entry: register all JS globals.
fn register_globals(world : @level.World, chunk_data : Array[UInt]) -> Unit {
  register_config(world, chunk_data)
  register_api(world)
}
