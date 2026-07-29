///|
/// Publish world-independent configuration before any JS module accesses
/// `globalThis.mc*` globals (e.g., IndexedDB reads `mcSaveSchemaVersion`).
#export_name("initializeGlobalConstants")
pub fn initialize_global_constants() -> Unit {
  @ffi.cast_global_set(
    "mcInfiniteWorldMinHeight",
    @level.INFINITE_WORLD_MIN_HEIGHT,
  )
  @ffi.cast_global_set(
    "mcInfiniteWorldMaxHeight",
    @level.INFINITE_WORLD_MAX_HEIGHT,
  )
  @ffi.cast_global_set(
    "mcInfiniteWorldDefaultHeight",
    @level.INFINITE_WORLD_DEFAULT_HEIGHT,
  )

  @ffi.cast_global_set("mcUpdateLabel", "1:10")
  @ffi.cast_global_set("mcSaveSchemaVersion", @save.SAVE_SCHEMA_VERSION)
  @ffi.cast_global_set("mcChunkSize", @level.CHUNK_X_SIZE)
  @ffi.cast_global_set(
    "mcRenderDistance",
    @render.DEFAULT_CHUNK_RENDER_DISTANCE,
  )
  @ffi.cast_global_set("mcChunkGenPerFrame", @render.CHUNK_GENERATION_BUDGET)
  @ffi.cast_global_set("mcMeshBuildPerFrame", @render.CHUNK_MESH_BUDGET)
  @ffi.cast_global_set("mcChunkSectionSize", @render.CHUNK_SECTION_SIZE)
  @ffi.cast_global_set("mcDebugChunkGen", false)
  @ffi.cast_global_set("mcDebugSolid", false)
  @ffi.cast_global_set("mcUseFixedLight", @level.USE_FIXED_LIGHT)
  @ffi.cast_global_set("mcFov", 60)
  @ffi.cast_global_set("mcInventoryGridX", @player.INVENTORY_GRID_X)
  @ffi.cast_global_set("mcInventoryGridY", @player.INVENTORY_GRID_Y)
  @ffi.cast_global_set("mcAirLongId", @schema.AIR_ID)
  @ffi.cast_global_set("mcWaterTintGridStep", 4)
  @ffi.cast_global_set("mcSpawnChunkX", @player.SPAWN_CHUNK_X)
  @ffi.cast_global_set("mcSpawnChunkZ", @player.SPAWN_CHUNK_Z)
  @ffi.cast_global_set("mcSpawnLocalX", @player.SPAWN_LOCAL_X)
  @ffi.cast_global_set("mcSpawnLocalZ", @player.SPAWN_LOCAL_Z)
  @ffi.cast_global_set("mcSpawnSurfaceOffset", @player.SPAWN_SURFACE_OFFSET)
  @ffi.cast_global_set("mcSpawnFallbackY", @player.SPAWN_FALLBACK_Y)
  @ffi.cast_global_set("mcSpawnYaw", @player.SPAWN_YAW)
  @ffi.cast_global_set("mcSpawnPitch", @player.SPAWN_PITCH)
  @ffi.cast_global_set("mcUpVector", @math3d.up_vector)
  @ffi.cast_global_set("mcOakLeavesVertexShader", @render.leaf_vertex_shader)
  @ffi.cast_global_set(
    "mcOakLeavesFragmentShader", @render.leaf_fragment_shader,
  )
  @ffi.cast_global_set("mcOakLeavesDefaultTint", @block_genus.default_tint)
}

///|
/// Create the selected world and publish the complete browser client API.
#export_name("launchGame")
pub fn launch_game(
  seed : UInt,
  world_type_name : String,
  height : Int,
  save_text : String,
) -> Unit {
  let world_type = @level.world_type_from_name(world_type_name)
  let world = @level.World::new(seed~, world_type~, height~)
  let initial_chunk = world.generate_chunk(0, 0, 0)
  initialize_client(world, initial_chunk.tile_map, save_text)
  @mob.install_default_demo(world)
}

///|
/// Publish configuration before callable APIs so browser startup observes a
/// complete, consistent client contract.
fn initialize_client(
  world : @level.World,
  chunk_data : Array[UInt],
  save_text : String,
) -> Unit {
  // Publish world-dependent configuration (overrides the early defaults).
  @ffi.cast_global_set("mcWorldSeed", world.seed())
  @ffi.cast_global_set("mcWorldType", world.world_type_name())
  @ffi.cast_global_set("mcWorldMinY", world.min_y())
  @ffi.cast_global_set("mcWorldMaxY", world.max_y())

  // Register the browser API by domain boundary. Each `mc*` name has exactly one owner in the client package.
  @client.register_render_api()
  @client.register_gameplay_api(world)
  @client.register_runtime_api(world, chunk_data, save_text)
}
