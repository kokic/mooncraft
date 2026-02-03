///|
/// Finite world size (blocks).
pub const FINITE_WORLD_X_SIZE : Int = 256

///|
/// Finite world size (blocks).
pub const FINITE_WORLD_Y_SIZE : Int = 128

///|
/// Finite world size (blocks).
pub const FINITE_WORLD_Z_SIZE : Int = 256

///|
pub const FINITE_MIN_Y : Int = -FINITE_WORLD_Y_SIZE / 2

///|
pub const FINITE_MAX_Y : Int = -FINITE_MIN_Y - 1

///|
pub const FINITE_CHUNK_X_HALF : Int = FINITE_WORLD_X_SIZE / (2 * CHUNK_X_SIZE)

///|
pub const FINITE_CHUNK_Y_HALF : Int = FINITE_WORLD_Y_SIZE / (2 * CHUNK_Y_SIZE)

///|
pub const FINITE_CHUNK_Z_HALF : Int = FINITE_WORLD_Z_SIZE / (2 * CHUNK_Z_SIZE)

///|
fn is_chunk_in_finite_world(
  chunk_x : Int,
  chunk_y : Int,
  chunk_z : Int,
) -> Bool {
  chunk_x >= -FINITE_CHUNK_X_HALF &&
  chunk_x < FINITE_CHUNK_X_HALF &&
  chunk_y >= -FINITE_CHUNK_Y_HALF &&
  chunk_y < FINITE_CHUNK_Y_HALF &&
  chunk_z >= -FINITE_CHUNK_X_HALF &&
  chunk_z < FINITE_CHUNK_X_HALF
}

///|
fn set_block_if_in_chunk(
  chunk : Chunk,
  wx : Int,
  wy : Int,
  wz : Int,
  long_id : UInt,
) -> Unit {
  let base_x = chunk.x * CHUNK_X_SIZE
  let base_y = chunk.y * CHUNK_Y_SIZE
  let base_z = chunk.z * CHUNK_Z_SIZE
  if wx < base_x || wx >= base_x + CHUNK_X_SIZE {
    return
  }
  if wy < base_y || wy >= base_y + CHUNK_Y_SIZE {
    return
  }
  if wz < base_z || wz >= base_z + CHUNK_Z_SIZE {
    return
  }
  let rx = wx - base_x
  let ry = wy - base_y
  let rz = wz - base_z
  chunk.set_tile(rx, ry, rz, long_id)
}

///|
fn _place_nether_spire_in_chunk(world : World, chunk : Chunk) -> Unit {
  let base_y = surface_height(world, 0, 0)
  let setter = fn(wx : Int, wy : Int, wz : Int, long_id : UInt) -> Unit {
    set_block_if_in_chunk(chunk, wx, wy, wz, long_id)
  }
  @structure.place_nether_spire(setter, 0, base_y, 0)
}

///|
/// Finite world terrain generation (256 x 128 x 256).
fn fill_finite(world : World, chunk : Chunk) -> Chunk {
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
        if wy < FINITE_MIN_Y {
          chunk.set_tile(rx, ry, rz, air)
        } else if wy == FINITE_MIN_Y {
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
  // _place_nether_spire_in_chunk(world, chunk)
  place_oak_trees_in_chunk(world, chunk)
  chunk
}
