///|
/// A world voxel resolved into chunk coordinates and local coordinates.
/// The chunk size must be positive; local coordinates are always in 0..<size.
pub struct BlockAddress {
  cx : Int
  cy : Int
  cz : Int
  x : Int
  y : Int
  z : Int
}

///|
pub fn BlockAddress::new(size : Int, wx : Int, wy : Int, wz : Int) -> BlockAddress {
  let cx = @util.floor_div(wx, size)
  let cy = @util.floor_div(wy, size)
  let cz = @util.floor_div(wz, size)
  { cx, cy, cz, x: wx - cx * size, y: wy - cy * size, z: wz - cz * size, }
}

///|
pub fn BlockAddress::chunk_key(self : BlockAddress) -> String {
  chunk_key_by_chunk_xyz(self.cx, self.cy, self.cz)
}

///|
pub fn BlockAddress::column_key(self : BlockAddress) -> String {
  chunk_column_key_by_chunk_xz(self.cx, self.cz)
}

///|
/// YZX storage index, optionally including a surrounding neighbor layer.
pub fn BlockAddress::index(
  self : BlockAddress,
  stride : Int,
  padding? : Int = 0,
) -> Int {
  ((self.y + padding) * stride + self.z + padding) * stride + self.x + padding
}
