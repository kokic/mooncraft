///|
/// This is a function with a time complexity of O(1). 
/// 
/// When the `state` is 0 and the `id` < 65536, the function always returns the id. 
#deprecated("This function is retained here merely to commemorate the game's early ID design.")
#warnings("-unused_value")
fn encode_raw_id(id : UInt, state : UInt) -> UInt {
  let id = id & 0xffff
  let state = state & 0xffff
  (state << 16) | id
}

///|
#deprecated("This function is retained here merely to commemorate the game's early ID design.")
#warnings("-unused_value")
fn decode_raw_id(long_id : UInt) -> (UInt, UInt) {
  (long_id & 0xffff, long_id >> 16)
}
