///|
/// Spawn probe chunk X coordinate.
pub const SPAWN_CHUNK_X : Int = 0

///|
/// Spawn probe chunk Z coordinate.
pub const SPAWN_CHUNK_Z : Int = 0

///|
/// Spawn probe local X in chunk.
pub const SPAWN_LOCAL_X : Int = @level.CHUNK_X_SIZE / 2

///|
/// Spawn probe local Z in chunk.
pub const SPAWN_LOCAL_Z : Int = @level.CHUNK_Z_SIZE / 2

///|
/// Spawn Y offset above detected surface.
pub const SPAWN_SURFACE_OFFSET : Int = 3

///|
/// Fallback Y used when no surface is found.
pub const SPAWN_FALLBACK_Y : Int = @level.CHUNK_Y_SIZE

///|
pub fn compute_spawn_position(
  chunk_map : @ffi.JsValue,
  size : Int,
  chunk_min_y : Int,
  chunk_max_y : Int,
  chunk_x : Int,
  chunk_z : Int,
  local_x : Int,
  local_z : Int,
  surface_offset : Int,
  fallback_y : Int,
) -> @level.SpawnResult {
  let surface_y = @level.find_surface_y(
    chunk_map, size, chunk_min_y, chunk_max_y, chunk_x, chunk_z, local_x, local_z,
  )
  let base_y = match surface_y {
    Some(v) => v
    None => fallback_y
  }
  let spawn_y = base_y + surface_offset
  let px = local_x.to_double() + 0.5
  let py = spawn_y.to_double()
  let pz = local_z.to_double() + 0.5
  let surface_out = match surface_y {
    Some(v) => v
    None => -1
  }
  @level.SpawnResult::{ position: [px, py, pz], surface_y: surface_out }
}
