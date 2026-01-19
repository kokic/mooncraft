///|
fn main {
  let ctx : @ffi.WebGL2RenderingContext? = @ffi.get_webgl2_ctx().to_option()
  guard ctx is Some(ctx) else {
    @ffi.console_err(
      "The context identifier is not supported, or the canvas has already been set to a different context mode",
    )
  }
  @ffi.console_log(ctx)
}
