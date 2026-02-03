///|
let blocks_by_name : Map[@util.UniqueName, Block] = {
  let out : Map[@util.UniqueName, Block] = Map::new()
  for block in blocks {
    if !out.contains(block.name) {
      out[block.name] = block
    }
  }
  out
}

///|
let blocks_by_long_id : Map[UInt, Block] = {
  let out : Map[UInt, Block] = Map::new()
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
pub fn lookup_by_long_id(long_id : UInt) -> Block? {
  blocks_by_long_id.get(long_id)
}

///|
pub fn name_to_long_id(name : String) -> UInt {
  match lookup_by_name(name) {
    Some(block) => block.long_id()
    None => AIR_LONG_ID
  }
}
