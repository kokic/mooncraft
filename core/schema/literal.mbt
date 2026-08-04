///|
pub fn clamp_int(
  token : StringView,
  min : Int,
  max : Int,
  message? : String = "parse error",
) -> Int raise {
  let value = @string.parse_int(token)
  guard value >= min && value <= max else { fail(message) }
  value
}

///|
pub fn query_int(
  token : StringView,
  min : Int?,
  max : Int?,
  message? : String = "parse error",
) -> Int raise {
  if min is Some(min) && max is Some(max) {
    clamp_int(token, min, max, message~)
  } else {
    @string.parse_int(token)
  }
}

///|
pub fn clamp_uint(
  token : StringView,
  min : UInt,
  max : UInt,
  message? : String = "parse error",
) -> UInt raise {
  let value = @string.parse_uint(token)
  guard value >= min && value <= max else { fail(message) }
  value
}

///|
pub fn query_uint(
  token : StringView,
  min : UInt?,
  max : UInt?,
  message? : String = "parse error",
) -> UInt raise {
  if min is Some(min) && max is Some(max) {
    clamp_uint(token, min, max, message~)
  } else {
    @string.parse_uint(token)
  }
}

///|
pub fn clamp_double(
  token : StringView,
  min : Double,
  max : Double,
  message? : String = "parse error",
) -> Double raise {
  let value = @string.parse_double(token)
  guard value >= min && value <= max else { fail(message) }
  value
}

///|
pub fn query_double(
  token : StringView,
  min : Double?,
  max : Double?,
  message? : String = "parse error",
) -> Double raise {
  if min is Some(min) && max is Some(max) {
    clamp_double(token, min, max, message~)
  } else {
    @string.parse_double(token)
  }
}
