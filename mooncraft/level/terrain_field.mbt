///|
/// Canonical terrain-field horizontal scale: how many field blocks one world
/// block spans. Infinite samples the field directly; Finite is a 1/3-scale,
/// 128-tall copy of the modern 384-tall field.
fn World::terrain_field_scale(self : World) -> Double {
  match self.kind {
    WorldType::Finite => FINITE_TERRAIN_SCALE
    _ => 1.0
  }
}

///|
/// World Y of this world's sea level.
pub fn World::sea_level(self : World) -> Int {
  match self.kind {
    WorldType::Finite => FINITE_SEA_LEVEL
    _ => SEA_LEVEL
  }
}

///|
/// Canonical-field X for a world X.
fn World::terrain_field_x(self : World, wx : Int) -> Double {
  wx.to_double() * self.terrain_field_scale()
}

///|
/// Canonical-field Z for a world Z.
fn World::terrain_field_z(self : World, wz : Int) -> Double {
  wz.to_double() * self.terrain_field_scale()
}

///|
/// Canonical-field Y for a world Y. Finite recenters its sea level and compresses
/// the field so its whole vertical range fits the shorter world.
fn World::terrain_field_y(self : World, wy : Int) -> Double {
  match self.kind {
    WorldType::Finite =>
      SEA_LEVEL.to_double() +
      (wy - FINITE_SEA_LEVEL).to_double() * FINITE_TERRAIN_SCALE
    _ => wy.to_double()
  }
}

///|
/// Inverse of `terrain_field_y`, used to place a field height in world space.
fn World::terrain_wy_at_field_y(self : World, field_y : Double) -> Double {
  match self.kind {
    WorldType::Finite =>
      FINITE_SEA_LEVEL.to_double() +
      (field_y - SEA_LEVEL.to_double()) / FINITE_TERRAIN_SCALE
    _ => field_y
  }
}

///|
/// World Y of the deepslate transition, so it keeps the same field depth in
/// both the tall Infinite field and the compressed Finite field.
fn World::deepslate_level(self : World) -> Int {
  self.terrain_wy_at_field_y(0.0).round().to_int()
}
