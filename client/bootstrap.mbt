///|
/// Install the browser entry points needed before a world is created.
pub fn bootstrap() -> Unit {
  publish_global("mcWorldTypes", @level.world_type_names())
  publish_global("mcInfiniteWorldMinHeight", @level.INFINITE_WORLD_MIN_HEIGHT)
  publish_global("mcInfiniteWorldMaxHeight", @level.INFINITE_WORLD_MAX_HEIGHT)
  publish_global(
    "mcInfiniteWorldDefaultHeight",
    @level.INFINITE_WORLD_DEFAULT_HEIGHT,
  )
  publish_global("mcLaunchGame", launch_game)
}

///|
/// Create the selected world and publish the complete browser client API.
fn launch_game(
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
  publish_client_config(world)
  register_client_api(world, chunk_data, save_text)
}
