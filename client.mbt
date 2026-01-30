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
  @ffi.set_global_value("mcWorldMinY", @ffi.JsValue::cast_from(@level.WORLD_MIN_Y))
  @ffi.set_global_value("mcWorldMaxY", @ffi.JsValue::cast_from(@level.WORLD_MAX_Y))
  @ffi.set_global_value(
    "mcCollectTextureNames",
    @ffi.JsValue::cast_from(@block.collect_texture_names),
  )
  @ffi.set_global_value(
    "mcCreateBlockRegistry",
    @ffi.JsValue::cast_from(@block.create_block_registry),
  )
  @ffi.set_global_value(
    "mcBlockIsSelectable",
    @ffi.JsValue::cast_from(@block.BlockRegistry::is_selectable),
  )
  @ffi.set_global_value(
    "mcBuildChunkMesh",
    @ffi.JsValue::cast_from(build_chunk_mesh),
  )
  @ffi.set_global_value(
    "mcBuildWorldMesh",
    @ffi.JsValue::cast_from(build_world_mesh),
  )
  let gen_chunk = fn(x : Int, y : Int, z : Int) -> Array[UInt] {
    world.generate_chunk(x, y, z).tile_map
  }
  @ffi.set_global_value("mcGenChunk", @ffi.JsValue::cast_from(gen_chunk))
}
