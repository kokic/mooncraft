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
/// Finite sea level in the world's origin-centered coordinates.
pub const FINITE_SEA_LEVEL : Int = 0

///|
/// How many canonical terrain-field blocks one Finite block spans. The 384-tall
/// field compresses into this 128-tall world while keeping sea level centered.
pub const FINITE_TERRAIN_SCALE : Double = 3.0

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
/// Whether this XZ column has real terrain. Finite is bounded, so columns past
/// its edges are generated as air; every other world type is unbounded.
fn World::is_column_generated(self : World, chunk_x : Int, chunk_z : Int) -> Bool {
  match self.kind {
    WorldType::Finite =>
      chunk_x >= -FINITE_CHUNK_X_HALF &&
      chunk_x < FINITE_CHUNK_X_HALF &&
      chunk_z >= -FINITE_CHUNK_Z_HALF &&
      chunk_z < FINITE_CHUNK_Z_HALF
    _ => true
  }
}

///|
fn ranges_overlap(min_a : Int, max_a : Int, min_b : Int, max_b : Int) -> Bool {
  !(max_a < min_b || max_b < min_a)
}

///|
fn chunk_intersects_nether_spire(world : World, chunk : Chunk) -> Bool {
  let base_y = terrain_column(world, 0, 0).surface
  let half = @structure.NETHER_SPIRE_SIZE / 2
  let min_x = -half
  let max_x = min_x + @structure.NETHER_SPIRE_SIZE - 1
  let min_z = -half
  let max_z = min_z + @structure.NETHER_SPIRE_SIZE - 1
  let min_y = base_y + @structure.NETHER_SPIRE_LAYER_Y_MIN
  let max_y = min_y + @structure.NETHER_SPIRE_HEIGHT - 1
  let chunk_min_x = chunk.x * CHUNK_X_SIZE
  let chunk_max_x = chunk_min_x + CHUNK_X_SIZE - 1
  let chunk_min_y = chunk.y * CHUNK_Y_SIZE
  let chunk_max_y = chunk_min_y + CHUNK_Y_SIZE - 1
  let chunk_min_z = chunk.z * CHUNK_Z_SIZE
  let chunk_max_z = chunk_min_z + CHUNK_Z_SIZE - 1
  ranges_overlap(min_x, max_x, chunk_min_x, chunk_max_x) &&
  ranges_overlap(min_y, max_y, chunk_min_y, chunk_max_y) &&
  ranges_overlap(min_z, max_z, chunk_min_z, chunk_max_z)
}

///|
fn place_nether_spire_in_chunk(world : World, chunk : Chunk) -> Unit {
  let base_y = terrain_column(world, 0, 0).surface
  let setter = fn(wx : Int, wy : Int, wz : Int, internal_id : UInt) -> Unit {
    Chunk::set_block(chunk, wx, wy, wz, internal_id)
  }
  @structure.place_nether_spire(setter, 0, base_y, 0)
}

///|
/// Place fixed structures that belong to a generated column. Finite hosts the
/// nether spire at the origin; other terrain types have none.
fn place_terrain_structures(world : World, chunks : Array[Chunk]) -> Unit {
  guard world.kind is WorldType::Finite else { return }
  for chunk in chunks {
    if chunk_intersects_nether_spire(world, chunk) {
      place_nether_spire_in_chunk(world, chunk)
    }
  }
}

///|
/// Finite world terrain generation (256 x 128 x 256). Shares the modern
/// spline/noise pipeline with Infinite, compressed into the shorter world.
fn fill_finite(world : World, chunk : Chunk) -> Chunk {
  let chunk = fill_terrain(world, chunk)
  place_terrain_structures(world, [chunk])
  chunk
}
