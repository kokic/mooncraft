///|
priv struct BlockIdCounter {
  mut value : UInt
}

///|
let counter : BlockIdCounter = BlockIdCounter::{ value: 0 }

///|
fn alloc_id() -> UInt {
  let id = counter.value
  counter.value = counter.value + 1
  id
}
