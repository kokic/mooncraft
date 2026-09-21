///|
/// Padded chunk sampling: resolves block render data and light at any
/// coordinate, treating out-of-bounds voxels as air (light 15).
priv struct PaddedChunk {
  registry : @block.RenderRegistry
  data : Array[UInt]
  light : Bytes
  size : Int
  pad : Int
  base_len : Int
  pad_len : Int
  air_block : @block.RenderBlock
}

///|
fn PaddedChunk::new(
  registry : @block.RenderRegistry,
  data : Array[UInt],
  light : Bytes,
  size : Int,
) -> PaddedChunk? {
  guard registry.get_by_name(@schema.AIR_NAME) is Some(air_block) else { None }
  let pad = size + 2
  Some({
    registry,
    data,
    light,
    size,
    pad,
    base_len: size * size * size,
    pad_len: pad * pad * pad,
    air_block,
  })
}

///|
fn PaddedChunk::sample_index(
  self : PaddedChunk,
  length : Int,
  x : Int,
  y : Int,
  z : Int,
) -> Int? {
  let (stride, offset) = if length == self.base_len {
    (self.size, 0)
  } else if length == self.pad_len {
    (self.pad, 1)
  } else {
    return None
  }
  let px = x + offset
  let py = y + offset
  let pz = z + offset
  guard px >= 0 && px < stride && py >= 0 && py < stride && pz >= 0 && pz < stride else {
    None
  }
  Some((py * stride + pz) * stride + px)
}

///|
fn PaddedChunk::block(self : PaddedChunk, x : Int, y : Int, z : Int) -> @block.RenderBlock {
  guard self.sample_index(self.data.length(), x, y, z) is Some(index) else {
    self.air_block
  }
  self.registry.get_by_internal_id(self.data[index]).unwrap_or(self.air_block)
}

///|
fn PaddedChunk::light(self : PaddedChunk, x : Int, y : Int, z : Int) -> Int {
  guard self.sample_index(self.light.length(), x, y, z) is Some(index) else {
    if self.light.length() == self.pad_len { 0 } else { 15 }
  }
  self.light[index].to_int()
}
