///|
pub fn random_time_based() -> @random.Rand {
  @random.Rand::chacha8(seed=generate_time_based_seed())
}

///|
pub fn generate_time_based_seed() -> Bytes {
  let timestamp = @env.now()
  let part1 = timestamp - 25
  let part2 = timestamp + 25
  let part3 = timestamp - 41
  let part4 = timestamp + 41
  uint64_array_to_bytes([part1, part2, part3, part4])
}

///|
pub fn uint64_array_to_bytes(values : Array[UInt64]) -> Bytes {
  Bytes::makei(32, fn(i) {
    let value_index = i / 8
    let byte_index = i % 8
    let value = values[value_index]
    match byte_index {
      // to_byte(): & 0xFFUL
      0 => value.to_byte()
      1 => (value >> 8).to_byte()
      2 => (value >> 16).to_byte()
      3 => (value >> 24).to_byte()
      4 => (value >> 32).to_byte()
      5 => (value >> 40).to_byte()
      6 => (value >> 48).to_byte()
      7 => (value >> 56).to_byte()
      _ => b'\x00' // unreachable!
    }
  })
}
