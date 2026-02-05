///|
let items_by_name : Map[@util.UniqueName, Item] = {
  let out : Map[@util.UniqueName, Item] = Map::new()
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
