///|
fn section_key(chunk_key : String, x : Int, y : Int, z : Int) -> String {
  "\{chunk_key}|\{x},\{y},\{z}"
}

///|
fn chunk_key_by_world(size : Int, wx : Int, wy : Int, wz : Int) -> String {
  @level.chunk_key_by_chunk_xyz(
    @util.floor_div(wx, size),
    @util.floor_div(wy, size),
    @util.floor_div(wz, size),
  )
}

///|
fn chunk_column_key_by_world(size : Int, wx : Int, wz : Int) -> String {
  @level.chunk_column_key_by_chunk_xz(
    @util.floor_div(wx, size),
    @util.floor_div(wz, size),
  )
}
