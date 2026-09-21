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
    Infinite => self.terrain_noise.sample_climate(wx, wz)
    Finite =>
      @biome.sample(
        self.noise,
        finite_scaled_coord(wx),
        finite_scaled_coord(wz),
      )
    _ => @biome.sample(self.noise, wx, wz)
  }
}

///|
fn terrain_column(world : World, wx : Int, wz : Int) -> TerrainColumn {
  guard !(world.kind is WorldType::Finite) else {
    finite_terrain_column(world, wx, wz)
  }
  let sample = world.climate_sample(wx, wz)
  let biome = @biome.biome_from_sample(sample)
  let surface_biome = surface_biome_from_column(world, sample, biome)
  let params = @biome.params(surface_biome)
  let plain = plain_height_with_biome(
    world, wx, wz, sample, surface_biome, params,
  )
  let surface = surface_height_with_params(world, wx, wz, sample, surface_biome)
  TerrainColumn::{ wx, wz, sample, biome, surface_biome, plain, surface, }
}
