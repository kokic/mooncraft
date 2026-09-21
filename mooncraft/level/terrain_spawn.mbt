///|
/// Choose a dry, moderate-height starting column. Infinite and Finite search a
/// bounded region in deterministic order; other world types keep their origin.
pub fn World::spawn_chunk_xz(self : World) -> (Int, Int) {
  match self.kind {
    WorldType::Infinite => self.search_spawn_chunk(32, 4)
    WorldType::Finite => self.search_spawn_chunk(FINITE_CHUNK_X_HALF - 1, 1)
    _ => (0, 0)
  }
}

///|
/// Search rings of chunk offsets for a land column whose height is moderate for
/// this world. The same canonical field lines drive both world types.
fn World::search_spawn_chunk(
  self : World,
  radius : Int,
  chunk_step : Int,
) -> (Int, Int) {
  let surface_min = self
    .terrain_wy_at_field_y((SEA_LEVEL + 3).to_double())
    .round()
    .to_int()
  let surface_max = self.terrain_wy_at_field_y(120.0).round().to_int()
  let top_min = self
    .terrain_wy_at_field_y((SEA_LEVEL + 2).to_double())
    .round()
    .to_int()
  let top_max = self.terrain_wy_at_field_y(140.0).round().to_int()
  for ring in 0..<=radius {
    for dx in -ring..<=ring {
      for dz in -ring..<=ring {
        guard dx == -ring || dx == ring || dz == -ring || dz == ring else {
          continue
        }
        let cx = dx * chunk_step
        let cz = dz * chunk_step
        let wx = cx * CHUNK_X_SIZE + CHUNK_X_SIZE / 2
        let wz = cz * CHUNK_Z_SIZE + CHUNK_Z_SIZE / 2
        let column = terrain_column(self, wx, wz)
        guard column.surface_biome is @biome.Plains ||
          column.surface_biome is @biome.Forest ||
          column.surface_biome is @biome.Desert else {
          continue
        }
        guard column.surface >= surface_min && column.surface < surface_max else {
          continue
        }
        let top = highest_solid_y(self, sample_column_densities(self, column))
        guard top >= top_min && top < top_max else { continue }
        return (cx, cz)
      }
    }
  }
  (0, 0)
}
