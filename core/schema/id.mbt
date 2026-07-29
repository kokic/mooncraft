///|
/// This is a function with a time complexity of O(1). 
/// 
/// When the `state` is 0 and the `id` < 65536, the function always returns the id. 
#export_name("encodeRawId")
pub fn encode_raw_id(id : UInt, state : UInt) -> UInt {
  let id = id & 0xffff
  let state = state & 0xffff
  (state << 16) | id
}

///|
#export_name("decodeRawId")
pub fn decode_raw_id(long_id : UInt) -> (UInt, UInt) {
  (long_id & 0xffff, long_id >> 16)
}

///|
test "Raw id invariants" {
  assert_eq(encode_raw_id(65535, 0), 65535)
  assert_eq(encode_raw_id(65536, 0), 0)
}
