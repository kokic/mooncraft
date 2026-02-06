///|
fn hex_nibble(unit : UInt16) -> Int {
  let zero : UInt16 = '0'
  let nine : UInt16 = '9'
  let lower_a : UInt16 = 'a'
  let lower_f : UInt16 = 'f'
  let upper_a : UInt16 = 'A'
  let upper_f : UInt16 = 'F'
  if unit >= zero && unit <= nine {
    unit.to_int() - zero.to_int()
  } else if unit >= lower_a && unit <= lower_f {
    10 + unit.to_int() - lower_a.to_int()
  } else if unit >= upper_a && unit <= upper_f {
    10 + unit.to_int() - upper_a.to_int()
  } else {
    panic()
  }
}

///|
fn hex_byte(hex : String, i : Int) -> Int {
  let hi = hex_nibble(hex[i])
  let lo = hex_nibble(hex[i + 1])
  (hi << 4) | lo
}

///|
fn byte_to_unit(v : Int) -> Float {
  Float::from_int(v) / 255.0F
}

///|
/// Parse `#RRGGBBAA`, `RRGGBBAA`, `#RRGGBB`, or `RRGGBB` to normalized RGBA.
/// Panics when the string format is invalid.
pub fn rgba(hex : String) -> Rgba {
  let hash : UInt16 = '#'
  let offset = if hex.length() > 0 && hex[0] == hash { 1 } else { 0 }
  let payload_len = hex.length() - offset
  if payload_len != 6 && payload_len != 8 {
    panic()
  }
  let r = hex_byte(hex, offset)
  let g = hex_byte(hex, offset + 2)
  let b = hex_byte(hex, offset + 4)
  let a = if payload_len == 8 { hex_byte(hex, offset + 6) } else { 255 }
  (byte_to_unit(r), byte_to_unit(g), byte_to_unit(b), byte_to_unit(a))
}

///|
fn approx_eq(a : Float, b : Float) -> Bool {
  let d = if a >= b { a - b } else { b - a }
  d <= 0.000001F
}

///|
test "parse_hex_rgba" {
  let (r0, g0, b0, a0) = rgba("#80ff00cc")
  assert_true(approx_eq(r0, 128.0F / 255.0F))
  assert_true(approx_eq(g0, 1.0F))
  assert_true(approx_eq(b0, 0.0F))
  assert_true(approx_eq(a0, 204.0F / 255.0F))
  let (r1, g1, b1, a1) = rgba("112233")
  assert_true(approx_eq(r1, 17.0F / 255.0F))
  assert_true(approx_eq(g1, 34.0F / 255.0F))
  assert_true(approx_eq(b1, 51.0F / 255.0F))
  assert_true(approx_eq(a1, 1.0F))
}
