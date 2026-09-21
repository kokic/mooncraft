///|
/// Choose a dry, moderate-height starting column for Infinite worlds. Other
/// world types keep their origin spawn. Search order is deterministic per seed.
pub fn World::spawn_chunk_xz(self : World) -> (Int, Int) {
  guard self.kind is Infinite else { (0, 0) }
  for radius in 0..<=32 {
    for dx in -radius..<=radius {
      for dz in -radius..<=radius {
        guard dx == -radius || dx == radius || dz == -radius || dz == radius else {
          continue
        }
        let cx = dx * 4
        let cz = dz * 4
        let wx = cx * CHUNK_X_SIZE + CHUNK_X_SIZE / 2
        let wz = cz * CHUNK_Z_SIZE + CHUNK_Z_SIZE / 2
        let column = terrain_column(self, wx, wz)
        guard column.surface_biome is @biome.Plains ||
          column.surface_biome is @biome.Forest ||
          column.surface_biome is @biome.Desert else {
          continue
        }
        guard column.surface >= SEA_LEVEL + 3 && column.surface < 120 else {
          continue
        }
        let top = highest_solid_y(self, sample_column_densities(self, column))
        guard top >= SEA_LEVEL + 2 && top < 140 else { continue }
        return (cx, cz)
      }
    }
  }
  (0, 0)
}
