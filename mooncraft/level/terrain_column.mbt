///|
pub(all) struct TerrainColumn {
  wx : Int
  wz : Int
  sample : @biome.BiomeSample
  biome : @biome.Biome
  surface_biome : @biome.Biome
  plain : Int
  surface : Int
}

///|
/// Sample the same climate coordinates used by this world's terrain generator.
pub fn World::climate_sample(
  self : World,
  wx : Int,
  wz : Int,
) -> @biome.BiomeSample {
  match self.kind {
    Infinite | Finite =>
      self.terrain_noise.sample_climate(
        self.terrain_field_x(wx),
        self.terrain_field_z(wz),
      )
    _ => @biome.sample(self.noise, wx, wz)
  }
}

///|
fn terrain_column(world : World, wx : Int, wz : Int) -> TerrainColumn {
  let sample = world.climate_sample(wx, wz)
  let shape = TerrainShape::from_climate(sample)
  let surface = preliminary_surface_height(shape, world)
  let biome = terrain_surface_biome(world, sample, surface)
  let surface_biome = biome
  let plain = surface
  TerrainColumn::{ wx, wz, sample, biome, surface_biome, plain, surface, }
}

///|
/// Surface biome used by this world's terrain palette and vegetation.
pub fn World::biome_at(self : World, wx : Int, wz : Int) -> @biome.Biome {
  match self.kind {
    Infinite | Finite => terrain_column(self, wx, wz).surface_biome
    _ => @biome.biome_from_sample(self.climate_sample(wx, wz))
  }
}
