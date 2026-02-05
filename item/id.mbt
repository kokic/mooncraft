///|
priv struct ItemIdCounter {
  mut value : UInt
}

///|
let counter : ItemIdCounter = ItemIdCounter::{ value: 0 }

///|
fn alloc_id() -> UInt {
  let id = counter.value
  counter.value = counter.value + 1
  id
}
