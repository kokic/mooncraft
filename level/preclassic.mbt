///|
/// Pre-classic world size (blocks).
pub const PRECLASSIC_WORLD_X_SIZE : Int = 256

///|
/// Pre-classic world size (blocks).
pub const PRECLASSIC_WORLD_Y_SIZE : Int = 64

///|
/// Pre-classic world size (blocks).
pub const PRECLASSIC_WORLD_Z_SIZE : Int = 256

///|
pub const PRECLASSIC_MIN_Y : Int = -PRECLASSIC_WORLD_Y_SIZE / 2

///|
pub const PRECLASSIC_MAX_Y : Int = -PRECLASSIC_MIN_Y - 1

///|
pub const PRECLASSIC_CHUNK_X_HALF : Int = PRECLASSIC_WORLD_X_SIZE /
  (2 * CHUNK_X_SIZE)

///|
pub const PRECLASSIC_CHUNK_Y_HALF : Int = PRECLASSIC_WORLD_Y_SIZE /
  (2 * CHUNK_Y_SIZE)

///|
pub const PRECLASSIC_CHUNK_Z_HALF : Int = PRECLASSIC_WORLD_Z_SIZE /
  (2 * CHUNK_Z_SIZE)

///|
fn is_chunk_in_preclassic_world(
  chunk_x : Int,
  chunk_y : Int,
  chunk_z : Int,
) -> Bool {
  chunk_x >= -PRECLASSIC_CHUNK_X_HALF &&
  chunk_x < PRECLASSIC_CHUNK_X_HALF &&
  chunk_y >= -PRECLASSIC_CHUNK_Y_HALF &&
  chunk_y < PRECLASSIC_CHUNK_Y_HALF &&
  chunk_z >= -PRECLASSIC_CHUNK_X_HALF &&
  chunk_z < PRECLASSIC_CHUNK_X_HALF
}

///|
const PRECLASSIC_BASE_HEIGHT : Double = 2.0

///|
const PRECLASSIC_ROLLING_FREQ : Double = 0.010

///|
const PRECLASSIC_ROLLING_AMP : Double = 8.0

///|
const PRECLASSIC_DETAIL_FREQ : Double = 0.029

///|
const PRECLASSIC_DETAIL_AMP : Double = 3.1

///|
const PRECLASSIC_WATER_LEVEL : Int = -4

///|
const PRECLASSIC_DIRT_SCALE : Double = 14.0

///|
const PRECLASSIC_SAND_PATCH_FREQ : Double = 0.023

///|
const PRECLASSIC_CAVE_FREQ_A : Double = 0.054

///|
const PRECLASSIC_CAVE_FREQ_B : Double = 0.081

///|
const PRECLASSIC_CAVE_THRESHOLD : Double = 0.14

///|
fn preclassic_surface_height(world : World, wx : Int, wz : Int) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let rolling = @biome.fbm2d(
      world.noise,
      x * PRECLASSIC_ROLLING_FREQ,
      z * PRECLASSIC_ROLLING_FREQ,
      4,
      2.0,
      0.5,
    ) *
    PRECLASSIC_ROLLING_AMP
  let detail = world.noise.gen2d(
      x * PRECLASSIC_DETAIL_FREQ,
      z * PRECLASSIC_DETAIL_FREQ,
    ) *
    PRECLASSIC_DETAIL_AMP
  let min_h = PRECLASSIC_MIN_Y + 3
  let max_h = PRECLASSIC_MAX_Y - 2
  let mut h = (PRECLASSIC_BASE_HEIGHT + rolling + detail).round().to_int()
  if h < min_h {
    h = min_h
  } else if h > max_h {
    h = max_h
  }
  h
}

///|
fn preclassic_dirt_depth(world : World, wx : Int, wz : Int) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let t = world.noise
    .gen2d(x / PRECLASSIC_DIRT_SCALE, z / PRECLASSIC_DIRT_SCALE)
    .abs()
  2 + (t * 2.0).floor().to_int()
}

///|
fn preclassic_is_sand_patch(
  world : World,
  wx : Int,
  wz : Int,
  surface : Int,
) -> Bool {
  if surface <= PRECLASSIC_WATER_LEVEL + 1 {
    true
  } else {
    let x = wx.to_double()
    let z = wz.to_double()
    world.noise.gen2d(
      x * PRECLASSIC_SAND_PATCH_FREQ,
      z * PRECLASSIC_SAND_PATCH_FREQ,
    ) >
    0.66
  }
}

///|
fn preclassic_should_carve_cave(
  world : World,
  wx : Int,
  wy : Int,
  wz : Int,
  surface : Int,
) -> Bool {
  if wy >= surface - 6 {
    false
  } else {
    let x = wx.to_double()
    let y = wy.to_double()
    let z = wz.to_double()
    let cave_a = world.noise
      .gen3d(
        x * PRECLASSIC_CAVE_FREQ_A,
        y * PRECLASSIC_CAVE_FREQ_A,
        z * PRECLASSIC_CAVE_FREQ_A,
      )
      .abs()
    let cave_b = world.noise
      .gen3d(
        (x + 173.0) * PRECLASSIC_CAVE_FREQ_B,
        y * PRECLASSIC_CAVE_FREQ_B,
        (z - 239.0) * PRECLASSIC_CAVE_FREQ_B,
      )
      .abs()
    let mix = cave_a * 0.68 + cave_b * 0.32
    let threshold = PRECLASSIC_CAVE_THRESHOLD +
      (surface - wy).to_double() * 0.0008
    mix < threshold
  }
}

///|
/// Pre-classic world terrain generation (256 x 64 x 256).
fn fill_preclassic(world : World, chunk : Chunk) -> Chunk {
  let air = @block.AIR_LONG_ID
  let bedrock = @block.lookup_by_name("bedrock").unwrap().id
  let stone = @block.lookup_by_name("pre-classic.cobblestone").unwrap().id
  let grass = @block.lookup_by_name("pre-classic.grass").unwrap().id
  let dirt = @block.lookup_by_name("dirt").unwrap().id
  let sand = @block.lookup_by_name("sand").unwrap().id
  let water = @block.lookup_by_name("water").unwrap().id
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      let (wx, _, wz) = chunk.block_rxyz_to_block_xyz(rx, 0, rz)
      let surface = preclassic_surface_height(world, wx, wz)
      let dirt_depth = preclassic_dirt_depth(world, wx, wz)
      let sand_patch = preclassic_is_sand_patch(world, wx, wz, surface)
      for ry in 0..<CHUNK_Y_SIZE {
        let (_, wy, _) = chunk.block_rxyz_to_block_xyz(rx, ry, rz)
        if wy < PRECLASSIC_MIN_Y {
          chunk.update_tile_map(rx, ry, rz, air)
        } else if wy == PRECLASSIC_MIN_Y {
          chunk.update_tile_map(rx, ry, rz, bedrock)
        } else if wy > surface {
          if wy <= PRECLASSIC_WATER_LEVEL && wy > surface {
            chunk.update_tile_map(rx, ry, rz, water)
          } else {
            chunk.update_tile_map(rx, ry, rz, air)
          }
        } else if preclassic_should_carve_cave(world, wx, wy, wz, surface) {
          chunk.update_tile_map(rx, ry, rz, air)
        } else if wy == surface {
          if sand_patch {
            chunk.update_tile_map(rx, ry, rz, sand)
          } else {
            chunk.update_tile_map(rx, ry, rz, grass)
          }
        } else if wy >= surface - dirt_depth {
          if sand_patch {
            chunk.update_tile_map(rx, ry, rz, sand)
          } else {
            chunk.update_tile_map(rx, ry, rz, dirt)
          }
        } else {
          chunk.update_tile_map(rx, ry, rz, stone)
        }
      }
    }
  }
  place_oak_trees_in_chunk(world, chunk, is_grass=long_id => long_id == grass)
  chunk
}
