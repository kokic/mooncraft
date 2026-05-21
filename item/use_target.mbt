///|
priv enum UseTarget {
  KnownItem(Item)
  KnownBlock(@util.UniqueName)
  Empty
  Unknown
}

///|
fn UseTarget::is_usable(target : UseTarget) -> Bool {
  match target {
    KnownItem(_) | KnownBlock(_) => true
    Empty | Unknown => false
  }
}

///|
fn UseTarget::from_wire(name : String, category : String) -> UseTarget {
  match Category::from_tag(category) {
    Some(Item) =>
      match lookup_by_name(name) {
        Some(item) => KnownItem(item)
        None => Unknown
      }
    Some(Block) => KnownBlock(name)
    Some(None) => Empty
    None => Unknown
  }
}
