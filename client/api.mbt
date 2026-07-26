///|
/// Register the browser API by domain boundary. Each `mc*` name has exactly
/// one owner in the client package.
fn register_client_api(world : @level.World, chunk_data : Array[UInt]) -> Unit {
  register_render_api()
  register_gameplay_api(world)
  register_runtime_api(world, chunk_data)
}
