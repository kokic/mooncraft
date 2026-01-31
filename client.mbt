///|
fn main {
  let ctx : @ffi.WebGL2RenderingContext? = @ffi.get_webgl2_ctx().to_option()
  guard ctx is Some(_) else {
    @ffi.console_err(
      "The context identifier is not supported, or the canvas has already been set to a different context mode",
    )
  }
  let world = @level.World::new(world_type=@level.PreClassic)
  let chunk = world.generate_chunk(0, 0, 0)
  @ffi.set_global_value(
    "mcChunkSize",
    @ffi.JsValue::cast_from(@level.CHUNK_X_SIZE),
  )
  @ffi.set_global_value("mcChunkData", @ffi.JsValue::cast_from(chunk.tile_map))
  @ffi.set_global_value(
    "mcWorldMinY",
    @ffi.JsValue::cast_from(@level.WORLD_MIN_Y),
  )
  @ffi.set_global_value(
    "mcWorldMaxY",
    @ffi.JsValue::cast_from(@level.WORLD_MAX_Y),
  )
  @ffi.set_global_value(
    "mcCollectTextureNames",
    @ffi.JsValue::cast_from(@block.collect_texture_names),
  )
  @ffi.set_global_value(
    "mcCollectBlockLightInfo",
    @ffi.JsValue::cast_from(@block.collect_block_light_info),
  )
  @ffi.set_global_value(
    "mcGetLongIdByName",
    @ffi.JsValue::cast_from(@block.get_long_id_by_name),
  )
  @ffi.set_global_value(
    "mcGetAirLongId",
    @ffi.JsValue::cast_from(@block.get_air_long_id),
  )
  @ffi.set_global_value(
    "mcCollectHotbarDefs",
    @ffi.JsValue::cast_from(@player.collect_hotbar_defs),
  )
  @ffi.set_global_value(
    "mcCollectTorchBounds",
    @ffi.JsValue::cast_from(@genus.Torch::collect_bounds),
  )
  @ffi.set_global_value(
    "mcGetTorchOutlinePad",
    @ffi.JsValue::cast_from(@genus.Torch::get_outline_pad),
  )
  @ffi.set_global_value(
    "mcCreateBlockRegistry",
    @ffi.JsValue::cast_from(@block.BlockRegistry::create),
  )
  @ffi.set_global_value(
    "mcBlockIsSelectable",
    @ffi.JsValue::cast_from(@block.BlockRegistry::is_selectable),
  )
  @ffi.set_global_value(
    "mcBuildChunkMesh",
    @ffi.JsValue::cast_from(@block.build_chunk_mesh),
  )
  @ffi.set_global_value(
    "mcBuildChunkColors",
    @ffi.JsValue::cast_from(@block.build_chunk_colors),
  )
  @ffi.set_global_value(
    "mcBuildWorldMesh",
    @ffi.JsValue::cast_from(@block.build_world_mesh),
  )
  @ffi.set_global_value(
    "mcComputeSpawnPosition",
    @ffi.JsValue::cast_from(@level.compute_spawn_position),
  )
  @ffi.set_global_value(
    "mcRaycastBlocks",
    @ffi.JsValue::cast_from(@level.raycast_blocks),
  )
  let gen_chunk = fn(x : Int, y : Int, z : Int) -> Array[UInt] {
    world.generate_chunk(x, y, z).tile_map
  }
  @ffi.set_global_value("mcGenChunk", @ffi.JsValue::cast_from(gen_chunk))
}
