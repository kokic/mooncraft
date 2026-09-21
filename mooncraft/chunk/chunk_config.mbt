///|
pub const DEFAULT_CHUNK_RENDER_DISTANCE : Int = 3

///|
pub const MIN_RENDER_DISTANCE : Int = 0

///|
pub const MAX_RENDER_DISTANCE : Int = 32

///|
pub const CHUNK_SECTION_SIZE : Int = 8

///|
pub const CHUNK_GENERATION_BUDGET : Int = 1

///|
pub const CHUNK_GENERATION_WORK_BUDGET : Int = 8

///|
pub const CHUNK_MESH_BUDGET : Int = 8

///|
/// Maximum voxel/queue operations spent advancing lighting in one frame.
const LIGHT_WORK_BUDGET : Int = 262144

///|
/// Vertical block radius kept mesh-resident around the player. Terrain data
/// remains in `chunk_map`; sections outside this window are built on demand.
pub const VERTICAL_MESH_RADIUS : Int = 48
