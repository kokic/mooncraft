///|
/// Pre-classic bottom layer Y (bedrock).
pub const PRECLASSIC_MIN_Y : Int = -32

///|
/// Pre-classic terrain generation (biomes, soil, caves).
fn fill_pre_classic(world : World, chunk : Chunk) -> Chunk {
  let air = @block.AIR_LONG_ID
  let bedrock = @block.lookup_by_name("bedrock").unwrap().id
  let stone = @block.lookup_by_name("stone").unwrap().id
  let grass = @block.lookup_by_name("grass").unwrap().id
  let dirt = @block.lookup_by_name("dirt").unwrap().id
  let sand = @block.lookup_by_name("sand").unwrap().id
  let sandstone = @block.lookup_by_name("sandstone").unwrap().id
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
          chunk.set_tile(rx, ry, rz, air)
        } else if wy == PRECLASSIC_MIN_Y {
          chunk.set_tile(rx, ry, rz, bedrock)
        } else if density <= 0.0 {
          chunk.set_tile(rx, ry, rz, air)
        } else if wy == surface {
          match biome {
            @biome.Desert => chunk.set_tile(rx, ry, rz, sand)
            _ => chunk.set_tile(rx, ry, rz, grass)
          }
        } else if biome is @biome.Desert && wy >= surface - sand_depth {
          chunk.set_tile(rx, ry, rz, sand)
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
  place_oak_trees_in_chunk(world, chunk)
  chunk
}
