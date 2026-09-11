///|
let items_by_name : @hashmap.HashMap[@schema.UniqueID, Item] = {
  let out : @hashmap.HashMap[@schema.UniqueID, Item] = @hashmap.HashMap([])
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
