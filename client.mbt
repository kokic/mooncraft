///|
fn main {
  let world = @level.World::new(world_type=@level.WorldType::Finite)
  let chunk = world.generate_chunk(0, 0, 0)

  // global vlaue set
  @ffi.cast_global_set("mcChunkSize", @level.CHUNK_X_SIZE)
  @ffi.cast_global_set("mcChunkData", chunk.tile_map)
  @ffi.cast_global_set("mcWorldMinY", world.min_y())
  @ffi.cast_global_set("mcWorldMaxY", world.max_y())
  @ffi.cast_global_set("mcRenderDistance", 2)
  @ffi.cast_global_set("mcChunkGenPerFrame", 2)
  @ffi.cast_global_set("mcMeshBuildPerFrame", 2)
  @ffi.cast_global_set("mcDebugChunkGen", false)
  @ffi.cast_global_set("mcDebugSolid", false)
  @ffi.cast_global_set("mcFov", 60)
  @ffi.cast_global_set("mcInventoryGridX", @player.INVENTORY_GRID_X)
  @ffi.cast_global_set("mcInventoryGridY", @player.INVENTORY_GRID_Y)
  @ffi.cast_global_set("mcAirLongId", @block.AIR_LONG_ID)
  @ffi.cast_global_set(
    "mcTorchStateFromPlacement",
    @genus.Torch::torch_state_from_placement,
  )
  @ffi.cast_global_set("mcOakLeavesVertexShader", @genus.leaf_vertex_shader)
  @ffi.cast_global_set("mcOakLeavesFragmentShader", @genus.leaf_fragment_shader)
  @ffi.cast_global_set("mcOakLeavesDefaultTint", @genus.default_tint)

  // global function set
  @ffi.cast_global_set("mcCollectTextureNames", @block.collect_texture_names)
  @ffi.cast_global_set(
    "mcCollectBlockLightInfo", @block.collect_block_light_info,
  )
  @ffi.cast_global_set("mcGetLongIdByName", @block.name_to_long_id)
  @ffi.cast_global_set("mcCollectHotbarDefs", @player.collect_hotbar_defs)
  @ffi.cast_global_set("mcCollectInventoryDefs", @player.collect_inventory_defs)
  @ffi.cast_global_set("mcCameraFromYawPitch", @player.camera_from_yaw_pitch)
  @ffi.cast_global_set("mcCollectTorchBounds", @genus.Torch::collect_bounds)
  @ffi.cast_global_set("mcGetTorchOutlinePad", @genus.Torch::get_outline_pad)
  @ffi.cast_global_set("mcCreateBlockRegistry", @block.BlockRegistry::create)
  @ffi.cast_global_set(
    "mcBlockIsSelectable",
    @block.BlockRegistry::is_selectable,
  )
  @ffi.cast_global_set("mcPackLongId", @util.pack_long_id)
  @ffi.cast_global_set("mcUnpackLongId", @util.unpack_long_id)
  @ffi.cast_global_set("mcChunkXyzByKey", @level.chunk_xyz_by_chunk_key)
  @ffi.cast_global_set("mcBuildChunkMesh", @block.build_chunk_mesh)
  @ffi.cast_global_set("mcBuildChunkColors", @block.build_chunk_colors)
  @ffi.cast_global_set("mcBuildWorldMesh", @block.build_world_mesh)
  @ffi.cast_global_set("mcBuildWorldMeshSplit", @block.build_world_mesh_split)
  @ffi.cast_global_set("mcBuildUiItemMesh", @block.build_ui_item_mesh)
  @ffi.cast_global_set("mcComputeSpawnPosition", @level.compute_spawn_position)
  @ffi.cast_global_set("mcRaycastBlocks", @level.raycast_blocks)
  @ffi.cast_global_set("mcGetBlockId", @level.get_block_id)
  @ffi.cast_global_set("mcSetBlockId", @level.set_block_id)
  @ffi.cast_global_set("mcGetBlockShapeDesc", @block.get_shape_desc)
  @ffi.cast_global_set(
    "mcComputePlacementState", @block.compute_placement_state,
  )
  @ffi.cast_global_set(
    "mcGetBiomeName",
    fn(wx : Int, wz : Int) -> String {
      let biome = @biome.biome_at(world.noise, wx, wz)
      @biome.name(biome)
    },
  )
  let gen_chunk = fn(x : Int, y : Int, z : Int) -> Array[UInt] {
    world.generate_chunk(x, y, z).tile_map
  }
  @ffi.cast_global_set("mcGenChunk", gen_chunk)
}
