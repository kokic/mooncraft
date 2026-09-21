///|
pub struct World {
  seed : UInt
  kind : WorldType
  infinite_height : Int
  noise : @util.PerlinNoise
  terrain_noise : TerrainNoiseRouter
}

///|
pub fn World::new(
  seed? : UInt = @env.now().to_uint(),
  world_type? : WorldType = WorldType::PreClassic,
  height? : Int = INFINITE_WORLD_DEFAULT_HEIGHT,
) -> World {
  let noise = @util.PerlinNoise::new(seed~)
  let terrain_noise = TerrainNoiseRouter::new(seed)
  let infinite_height = normalize_infinite_world_height(height)
  World::{ seed, kind: world_type, infinite_height, noise, terrain_noise, }
}

///|
pub fn World::seed(self : World) -> UInt {
  self.seed
}

///|
pub fn World::world_type(self : World) -> WorldType {
  self.kind
}

///|
pub fn World::world_type_name(self : World) -> String {
  world_type_name(self.kind)
}

///|
/// Total vertical block span for this world.
pub fn World::height(self : World) -> Int {
  match self.kind {
    WorldType::Infinite => self.infinite_height
    _ => self.max_y() - self.min_y() + 1
  }
}

///|
pub fn World::min_y(self : World) -> Int {
  match self.kind {
    WorldType::Finite => FINITE_MIN_Y
    WorldType::PreClassic => PRECLASSIC_MIN_Y
    WorldType::Design => DESIGN_MIN_Y
    _ => WORLD_MIN_Y
  }
}

///|
pub fn World::max_y(self : World) -> Int {
  match self.kind {
    WorldType::Infinite => WORLD_MIN_Y + self.infinite_height - 1
    WorldType::Finite => FINITE_MAX_Y
    WorldType::PreClassic => PRECLASSIC_MAX_Y
    WorldType::Design => DESIGN_MAX_Y
    _ => WORLD_MAX_Y
  }
}
