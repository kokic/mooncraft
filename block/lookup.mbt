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
let blocks_by_internal_id : Map[@schema.InternalID, Block] = {
  let out : Map[@schema.InternalID, Block] = Map([])
  for block in blocks {
    out[block.internal_id()] = block
  }
  out
}

///|
pub fn lookup_by_name(name : String) -> Block? {
  blocks_by_name.get(name)
}

///|
pub fn lookup_by_internal_id(internal_id : @schema.InternalID) -> Block? {
  blocks_by_internal_id.get(internal_id)
}

///|
pub fn name_to_internal_id(name : String) -> @schema.InternalID {
  lookup_by_name(name).map(block => block.internal_id()).unwrap_or(@schema.AIR_ID)
}


