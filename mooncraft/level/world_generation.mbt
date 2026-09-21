///|
fn fill_air(chunk : Chunk) -> Chunk {
  let air = @schema.AIR_ID
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      for ry in 0..<CHUNK_Y_SIZE {
        chunk.update_tile_map(rx, ry, rz, air)
      }
    }
  }
  chunk
}

///|
pub fn World::generate_chunk(
  world : World,
  chunk_x : Int,
  chunk_y : Int,
  chunk_z : Int,
) -> Chunk {
  let chunk = Chunk::new(chunk_x, chunk_y, chunk_z)
  match world.kind {
    WorldType::Flat => fill_flat(world, chunk)
    WorldType::Infinite => fill_terrain(world, chunk)
    WorldType::PreClassic =>
      if is_chunk_in_preclassic_world(chunk_x, chunk_y, chunk_z) {
        fill_preclassic(world, chunk)
      } else {
        fill_air(chunk)
      }
    WorldType::Finite =>
      if is_chunk_in_finite_world(chunk_x, chunk_y, chunk_z) {
        fill_finite(world, chunk)
      } else {
        fill_air(chunk)
      }
    WorldType::Design =>
      if is_chunk_in_design_world(chunk_x, chunk_y, chunk_z) {
        fill_design(world, chunk)
      } else {
        fill_air(chunk)
      }
  }
}

///|
pub fn World::generate_chunk_column(
  world : World,
  chunk_x : Int,
  chunk_z : Int,
) -> Array[Chunk] {
  if world.kind is WorldType::Infinite || world.kind is WorldType::Finite {
    return generate_terrain_chunk_column(world, chunk_x, chunk_z)
  }
  let chunks : Array[Chunk] = []
  let chunk_min_y = @util.floor_div(world.min_y(), CHUNK_Y_SIZE)
  let chunk_max_y = @util.floor_div(world.max_y(), CHUNK_Y_SIZE)
  for chunk_y in chunk_min_y..<=chunk_max_y {
    chunks.push(world.generate_chunk(chunk_x, chunk_y, chunk_z))
  }
  chunks
}
