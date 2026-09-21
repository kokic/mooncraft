///|
/// A mesh section addressed relative to its owning level chunk.
pub struct ChunkSection {
  chunk_key : String
  x : Int
  y : Int
  z : Int
} derive(Debug, ToJson)

///|
pub extend ChunkSection with Debug::{to_repr}

///|
pub extend ChunkSection with ToJson::{to_json}

///|
/// One MoonBit-prepared mesh upload for a level section.
pub struct ChunkMeshCommand {
  chunk_key : String
  x : Int
  y : Int
  z : Int
  center_x : Double
  center_y : Double
  center_z : Double
  mesh : @mesh.MeshSplit
}

///|
/// One MoonBit-prepared color-buffer update for a rendered section.
pub struct ChunkRecolorCommand {
  chunk_key : String
  x : Int
  y : Int
  z : Int
  colors : @mesh.MeshColorsSplit
}

///|
/// Work emitted by one world-runtime tick. The browser executes these commands
/// only by creating, replacing, recoloring, or disposing WebGL resources.
pub struct ChunkRenderFrame {
  generated : Array[String]
  evicted : Array[String]
  mesh_updates : Array[ChunkMeshCommand]
  recolors : Array[ChunkRecolorCommand]
}
