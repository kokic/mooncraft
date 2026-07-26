///|
/// Install the browser entry points needed before a world is created.
pub fn bootstrap() -> Unit {
  publish_global("mcWorldTypes", @level.world_type_names())
  publish_global("mcLaunchGame", launch_game)
}

///|
/// Create the selected world and publish the complete browser client API.
fn launch_game() -> Unit {
  let seed = @ffi.load_saved_world_seed(@env.now().to_uint())
  let world_type_name = @ffi.load_saved_world_type(
    @ffi.new_world_type("Infinite"),
  )
  let world_type = @level.world_type_from_name(world_type_name)
  let world = @level.World::new(seed~, world_type~)
  let initial_chunk = world.generate_chunk(0, 0, 0)
  initialize_client(world, initial_chunk.tile_map)
  @mob.install_default_demo(world)
}

///|
/// Publish configuration before callable APIs so browser startup observes a
/// complete, consistent client contract.
fn initialize_client(world : @level.World, chunk_data : Array[UInt]) -> Unit {
  publish_client_config(world)
  register_client_api(world, chunk_data)
}
