///|
fn main {
  let world = @level.World::new(world_type=@level.WorldType::Finite)
  let chunk = world.generate_chunk(0, 0, 0)
  register_js_globals(world, chunk.tile_map)
}
