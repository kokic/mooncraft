///|
fn main {
  let default_world_type = @level.WorldType::Infinite
  let default_world_type_name = @level.world_type_name(default_world_type)
  let seed = @ffi.load_saved_world_seed(@env.now())
  let world_type_name = @ffi.load_saved_world_type(default_world_type_name)
  let world_type = @level.world_type_from_name(
    world_type_name,
    fallback=default_world_type,
  )
  let world = @level.World::new(seed~, world_type~)
  let chunk = world.generate_chunk(0, 0, 0)

  // let surface = @level.surface_height(world, 0, 0)
  // chunk.set_block(0, surface + 3, 0, @block.lookup_by_name("glass").unwrap().id)
  // chunk.set_block(0, surface + 4, 0, @block.lookup_by_name("cactus").unwrap().id)

  register_globals(world, chunk.tile_map)
  @mob.install_default_demo(world)
}
