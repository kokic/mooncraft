///|
/// Highest world Y for Flat worlds and default Infinite worlds.
pub const WORLD_MAX_Y : Int = 319

///|
/// Lowest world Y for Infinite/Flat worlds.
pub const WORLD_MIN_Y : Int = -64

///|
/// Minimum selectable Infinite-world height. This preserves terrain below and
/// above sea level while reducing vertical chunk work.
pub const INFINITE_WORLD_MIN_HEIGHT : Int = 192

///|
/// Default selectable Infinite-world height.
pub const INFINITE_WORLD_DEFAULT_HEIGHT : Int = 192

///|
/// Maximum selectable Infinite-world height. Taller worlds increase the amount
/// of chunk generation and meshing work for every XZ column.
pub const INFINITE_WORLD_MAX_HEIGHT : Int = INFINITE_WORLD_DEFAULT_HEIGHT

///|
/// Minecraft-like sea level baseline.
pub const SEA_LEVEL : Int = 63

///|
#export_name("normalizeInfiniteWorldHeight")
pub fn normalize_infinite_world_height(height : Int) -> Int {
  if height >= INFINITE_WORLD_MIN_HEIGHT && height <= INFINITE_WORLD_MAX_HEIGHT {
    height
  } else {
    INFINITE_WORLD_MIN_HEIGHT
  }
}
