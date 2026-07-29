///|
let blocks_by_name : Map[@schema.UniqueID, Block] = {
  let out : Map[@schema.UniqueID, Block] = Map([])
  for block in blocks {
    if !out.contains(block.name) {
      out[block.name] = block
    }
  }
  out
}

///|
let blocks_by_long_id : Map[@schema.InternalID, Block] = {
  let out : Map[@schema.InternalID, Block] = Map([])
  for block in blocks {
    out[block.long_id()] = block
  }
  out
}

///|
pub fn lookup_by_name(name : String) -> Block? {
  blocks_by_name.get(name)
}

///|
pub fn lookup_by_long_id(long_id : @schema.InternalID) -> Block? {
  blocks_by_long_id.get(long_id)
}

///|
pub fn name_to_long_id(name : String) -> @schema.InternalID {
  lookup_by_name(name).map(block => block.long_id()).unwrap_or(@schema.AIR_ID)
}

///
let blocks_by_id : Map[UInt, Block] = {
  let out : Map[UInt, Block] = Map([])
  for block in blocks {
    if !out.contains(block.id) {
      out[block.id] = block
    }
  }
  out
}

///
pub fn lookup_by_id(id : UInt) -> Block? {
  blocks_by_id.get(id)
}
