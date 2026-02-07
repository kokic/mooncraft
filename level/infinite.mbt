///|
/// Infinite bottom layer Y (bedrock).
pub const INFINITE_MIN_Y : Int = -32

///|
/// Infinite terrain generation (biomes, soil, caves).
fn fill_infinite(world : World, chunk : Chunk) -> Chunk {
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
      let column = terrain_column(world, wx, wz)
      let biome = column.biome
      let dirt_depth = surface_dirt_depth(world, wx, wz)
      let sand_depth = desert_sand_depth(world, wx, wz)
      let surface = column.surface
      for ry in 0..<CHUNK_Y_SIZE {
        let (_, wy, _) = chunk.block_rxyz_to_block_xyz(rx, ry, rz)
        let density = density_at_column(world, column, wy)
        if wy < INFINITE_MIN_Y {
          chunk.update_tile_map(rx, ry, rz, air)
        } else if wy == INFINITE_MIN_Y {
          chunk.update_tile_map(rx, ry, rz, bedrock)
        } else if density <= 0.0 {
          chunk.update_tile_map(rx, ry, rz, air)
        } else if wy == surface {
          match biome {
            @biome.Desert => chunk.update_tile_map(rx, ry, rz, sand)
            _ => chunk.update_tile_map(rx, ry, rz, grass)
          }
        } else if biome is @biome.Desert && wy >= surface - sand_depth {
          chunk.update_tile_map(rx, ry, rz, sand)
        } else if biome is @biome.Desert &&
          wy >= surface - sand_depth - DESERT_SANDSTONE_DEPTH {
          chunk.update_tile_map(rx, ry, rz, sandstone)
        } else if wy >= surface - dirt_depth {
          chunk.update_tile_map(rx, ry, rz, dirt)
        } else {
          chunk.update_tile_map(rx, ry, rz, stone)
        }
      }
    }
  }
  place_oak_trees_in_chunk(world, chunk)
  chunk
}
