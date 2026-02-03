///|
/// This is a function with a time complexity of O(1). 
/// 
/// When the `state` is 0 and the `id` < 65536, the function always returns the id. 
pub fn pack_long_id(id : UInt, state : UInt) -> UInt {
  let id = id & 0xffff
  let state = state & 0xffff
  (state << 16) | id
}

///|
pub fn unpack_long_id(long_id : UInt) -> (UInt, UInt) {
  (long_id & 0xffff, long_id >> 16)
}

///|
test "Long id invariants" {
  assert_eq(pack_long_id(65535, 0), 65535)
  assert_eq(pack_long_id(65536, 0), 0)
}
