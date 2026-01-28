///|
fn main {
  let ctx : @ffi.WebGL2RenderingContext? = @ffi.get_webgl2_ctx().to_option()
  guard ctx is Some(_) else {
    @ffi.console_err(
      "The context identifier is not supported, or the canvas has already been set to a different context mode",
    )
  }
  let world = @level.World::new(world_type=@level.WorldType::preclassic())
  let chunk = world.generate_chunk(0, 0, 0)
  @ffi.set_global_value(
    "mcChunkSize",
    @ffi.JsValue::cast_from(@level.CHUNK_X_SIZE),
  )
  @ffi.set_global_value("mcChunkData", @ffi.JsValue::cast_from(chunk.tile_map))
}
