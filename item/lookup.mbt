///|
let items_by_name : Map[@schema.UniqueID, Item] = {
  let out : Map[@schema.UniqueID, Item] = Map([])
  for item in items {
    if !out.contains(item.name) {
      out[item.name] = item
    }
  }
  out
}

///|
pub fn lookup_by_name(name : String) -> Item? {
  items_by_name.get(name)
}
