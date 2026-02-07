///|
fn main {
  let world = @level.World::new(world_type=@level.WorldType::Finite)
  let chunk = world.generate_chunk(0, 0, 0)

  // let surface = @level.surface_height(world, 0, 0)
  // chunk.set_block(0, surface + 3, 0, @block.lookup_by_name("glass").unwrap().id)
  // chunk.set_block(0, surface + 4, 0, @block.lookup_by_name("cactus").unwrap().id)

  register_globals(world, chunk.tile_map)
}
