///|
/// Pre-classic terrain generation (biomes, soil, caves).
fn fill_pre_classic(world : World, chunk : Chunk) -> Chunk {
  let air_id = @block.pack_long_id(@block.block_air.id, @block.block_air.state)
  let bedrock = @block.block_bedrock.long_id()
  let stone = @block.block_stone.long_id()
  let grass = @block.block_grass.long_id()
  let dirt = @block.block_dirt.long_id()
  let sand_id = @block.block_sand.long_id()
  let sandstone = @block.block_sandstone.long_id()
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      let (wx, _, wz) = chunk.block_rxyz_to_block_xyz(rx, 0, rz)
      let biome = @biome.biome_at(world.noise, wx, wz)
      let dirt_depth = surface_dirt_depth(world, wx, wz)
      let sand_depth = desert_sand_depth(world, wx, wz)
      let surface = surface_height(world, wx, wz)
      
      for ry in 0..<CHUNK_Y_SIZE {
        let (_, wy, _) = chunk.block_rxyz_to_block_xyz(rx, ry, rz)
        let density = density_at(world, wx, wy, wz)
        if wy < PRECLASSIC_MIN_Y {
          chunk.set_tile(rx, ry, rz, air_id)
        } else if wy == PRECLASSIC_MIN_Y {
          chunk.set_tile(rx, ry, rz, bedrock)
        } else if density <= 0.0 {
          chunk.set_tile(rx, ry, rz, air_id)
        } else if wy == surface {
          match biome {
            @biome.Desert => chunk.set_tile(rx, ry, rz, sand_id)
            _ => chunk.set_tile(rx, ry, rz, grass)
          }
        } else if biome is @biome.Desert && wy >= surface - sand_depth {
          chunk.set_tile(rx, ry, rz, sand_id)
        } else if biome is @biome.Desert &&
          wy >= surface - sand_depth - DESERT_SANDSTONE_DEPTH {
          chunk.set_tile(rx, ry, rz, sandstone)
        } else if wy >= surface - dirt_depth {
          chunk.set_tile(rx, ry, rz, dirt)
        } else {
          chunk.set_tile(rx, ry, rz, stone)
        }
      }
    }
  }
  chunk
}
