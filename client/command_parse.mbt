///|
fn parse_decimal3(
  x : StringView,
  y : StringView,
  z : StringView,
) -> (Double, Double, Double) raise {
  (@string.parse_double(x), @string.parse_double(y), @string.parse_double(z))
}

///|
fn clamp_int(token : StringView, min : Int, max : Int) -> Int raise {
  let v = @string.parse_int(token)
  guard v >= min && v <= max else { fail("parse error") }
  v
}

///|
fn clamp_double(token : StringView, min : Double, max : Double) -> Double raise {
  let v = @string.parse_double(token)
  guard v >= min && v <= max else { fail("parse error") }
  v
}

// ── ParseScope ──

///|
priv struct ParseScope {
  tokens : Array[StringView]
  mut pos : Int
}

///|
fn ParseScope::new(tokens : Array[StringView]) -> ParseScope {
  { tokens, pos: 1 }
}

///|
fn ParseScope::take_string(
  self : ParseScope,
  default? : String? = None,
) -> String raise {
  guard self.pos < self.tokens.length() else {
    guard default is Some(v) else { fail("parse error") }
    return v
  }
  if self.tokens[self.pos] == "~" {
    self.pos = self.pos + 1
    guard default is Some(v) else { fail("parse error") }
    return v
  }
  let v = self.tokens[self.pos].to_owned()
  self.pos = self.pos + 1
  v
}

///|
fn ParseScope::take_double(
  self : ParseScope,
  min? : Double? = None,
  max? : Double? = None,
  default? : Double? = None,
) -> Double raise {
  guard self.pos < self.tokens.length() else {
    guard default is Some(v) else { fail("parse error") }
    return v
  }
  if self.tokens[self.pos] == "~" {
    self.pos = self.pos + 1
    guard default is Some(v) else { fail("parse error") }
    return v
  }
  let token = self.tokens[self.pos]
  self.pos = self.pos + 1

  if min is Some(min) && max is Some(max) {
    clamp_double(token, min, max)
  } else {
    @string.parse_double(token)
  }
}

///|
fn ParseScope::take_int(
  self : ParseScope,
  min? : Int? = None,
  max? : Int? = None,
  default? : Int? = None,
) -> Int raise {
  guard self.pos < self.tokens.length() else {
    guard default is Some(v) else { fail("parse error") }
    return v
  }
  if self.tokens[self.pos] == "~" {
    self.pos = self.pos + 1
    guard default is Some(v) else { fail("parse error") }
    return v
  }
  let token = self.tokens[self.pos]
  self.pos = self.pos + 1

  if min is Some(min) && max is Some(max) {
    clamp_int(token, min, max)
  } else {
    @string.parse_int(token)
  }
}

///|
fn ParseScope::take_uint(
  self : ParseScope,
  default? : UInt? = None,
) -> UInt raise {
  guard self.pos < self.tokens.length() else {
    guard default is Some(v) else { fail("parse error") }
    return v
  }
  if self.tokens[self.pos] == "~" {
    self.pos = self.pos + 1
    guard default is Some(v) else { fail("parse error") }
    return v
  }
  let token = self.tokens[self.pos]
  self.pos = self.pos + 1
  @string.parse_uint(token)
}

///|
fn ParseScope::remainder(self : ParseScope) -> Array[StringView] {
  let r : Array[StringView] = []
  for i in self.pos..<self.tokens.length() {
    r.push(self.tokens[i])
  }
  r
}

///|
fn parse(
  tokens : Array[StringView],
  usage : String,
  run : (ParseScope) -> Result[String, String] raise,
) -> Result[String, String] {
  guard tokens.length() >= 1 else { return Err(usage) }
  let scope = ParseScope::new(tokens)
  run(scope) catch {
    error => Err("\{error}\n" + usage)
  }
}
