///|
/// Persistent overrides grouped by owning chunk. Each voxel has one stored
/// delta; generation reads only the overrides belonging to its chunk.
priv struct BlockEdits {
  chunks : @hashmap.HashMap[String, @hashmap.HashMap[String, @level.BlockDelta]]
}

///|
fn BlockEdits::new() -> BlockEdits {
  { chunks: @hashmap.HashMap([]), }
}

///|
fn BlockEdits::record(self : BlockEdits, size : Int, delta : @level.BlockDelta) -> Unit {
  let chunk_key = @level.BlockAddress::new(size, delta.x, delta.y, delta.z).chunk_key()
  let block_key = "\{delta.x},\{delta.y},\{delta.z}"
  if self.chunks.get(chunk_key) is Some(changes) {
    changes[block_key] = delta
  } else {
    let changes : @hashmap.HashMap[String, @level.BlockDelta] = @hashmap.HashMap([])
    changes[block_key] = delta
    self.chunks[chunk_key] = changes
  }
}

///|
fn BlockEdits::apply(
  self : BlockEdits,
  size : Int,
  chunk_key : String,
  data : Array[UInt],
) -> Unit {
  guard self.chunks.get(chunk_key) is Some(changes) else { () }
  for delta in changes.values() {
    let address = @level.BlockAddress::new(size, delta.x, delta.y, delta.z)
    data[address.index(size)] = @block.name_to_internal_id(delta.id)
  }
}

///|
fn BlockEdits::snapshot(self : BlockEdits) -> Array[@level.BlockDelta] {
  let deltas : Array[@level.BlockDelta] = []
  for changes in self.chunks.values() {
    for delta in changes.values() {
      deltas.push(delta)
    }
  }
  deltas
}
