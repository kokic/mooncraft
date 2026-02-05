///|
/// JS bootstrap globals consumed by `dist/js/*`.
/// Keep names stable to avoid breaking JS-side imports.
fn[V] set_global(name : String, value : V) -> Unit {
  @ffi.cast_global_set(name, value)
}

///|
/// Register scalar config and initial world state for JS bootstrap.
fn register_config(world : @level.World, chunk_data : Array[UInt]) -> Unit {
  set_global("mcChunkSize", @level.CHUNK_X_SIZE)
  set_global("mcChunkData", chunk_data)
  set_global("mcWorldMinY", world.min_y())
  set_global("mcWorldMaxY", world.max_y())
  set_global("mcRenderDistance", 2)
  set_global("mcChunkGenPerFrame", 2)
  set_global("mcMeshBuildPerFrame", 2)
  set_global("mcDebugChunkGen", false)
  set_global("mcDebugSolid", false)
  set_global("mcFov", 60)
  set_global("mcInventoryGridX", @player.INVENTORY_GRID_X)
  set_global("mcInventoryGridY", @player.INVENTORY_GRID_Y)
  set_global("mcAirLongId", @block.AIR_LONG_ID)

  // Leaf shader pipeline assets.
  set_global("mcOakLeavesVertexShader", @genus.leaf_vertex_shader)
  set_global("mcOakLeavesFragmentShader", @genus.leaf_fragment_shader)
  set_global("mcOakLeavesDefaultTint", @genus.default_tint)
}

///|
/// Register JS-callable entry points that forward to MoonBit logic.
fn register_api(world : @level.World) -> Unit {
  set_global(
    "mcTorchStateFromPlacement",
    @genus.Torch::torch_state_from_placement,
  )
  set_global("mcCollectTextureNames", @block.collect_texture_names)
  set_global("mcCollectBlockLightInfo", @block.collect_block_light_info)
  set_global("mcGetLongIdByName", @block.name_to_long_id)
  set_global("mcCollectHotbarItems", @player.collect_hotbar_items)
  set_global("mcCollectInventoryItems", @player.collect_inventory_items)
  set_global("mcCameraFromYawPitch", @player.camera_from_yaw_pitch)
  set_global("mcTorchShapeBoxByState", @block.torch_shape_box_by_state)
  set_global("mcCreateBlockRegistry", @block.BlockRegistry::create)
  set_global("mcGetRenderBlockByLongId", @block.BlockRegistry::get_by_long_id)
  set_global("mcBlockIsSelectable", @block.Block::is_selectable)
  set_global("mcPackLongId", @util.pack_long_id)
  set_global("mcUnpackLongId", @util.unpack_long_id)
  set_global("mcChunkXyzByKey", @level.chunk_xyz_by_chunk_key)
  set_global("mcCollectRenderChunkKeys", @level.collect_render_chunk_keys)
  set_global("mcCanPlaceBlock", @player.can_place_block)
  set_global("mcMat4Mul", @util.mat4_mul)
  set_global("mcMat4Ortho", @util.mat4_ortho)
  set_global("mcMat4Perspective", @util.mat4_perspective)
  set_global("mcMat4LookAt", @util.mat4_look_at)
  set_global("mcBuildChunkMesh", @block.build_chunk_mesh)
  set_global("mcBuildChunkColors", @block.build_chunk_colors)
  set_global("mcBuildChunkColorsSplit", @block.build_chunk_colors_split)
  set_global("mcBuildWorldMesh", @block.build_world_mesh)
  set_global("mcBuildWorldMeshSplit", @block.build_world_mesh_split)
  set_global("mcBuildWorldLight", @level.build_world_light)
  set_global("mcBuildUiItemMesh", @block.build_ui_item_mesh)
  set_global("mcComputeSpawnPosition", @level.compute_spawn_position)
  set_global("mcRaycastBlocks", @level.raycast_blocks)
  set_global("mcGetBlockId", @level.get_block_id)
  set_global("mcSetBlockId", @level.set_block_id)
  set_global("mcGetBlockShapeDesc", @block.get_shape_desc)
  set_global("mcComputePlacementState", @block.compute_placement_state)
  set_global("mcMovePlayer", @player.move_player)
  set_global("mcUseItemOn", @item.use_item_on_block)
  set_global("mcGetItemDisplayName", @i18n.item_display_name)
  set_global("mcGetBiomeName", fn(wx : Int, wz : Int) -> String {
    let biome = @biome.biome_at(world.noise, wx, wz)
    @biome.name(biome)
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
