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
    guard default is Some(value) else { fail("parse error") }
    return value
  }
  if self.tokens[self.pos] == "~" {
    self.pos = self.pos + 1
    guard default is Some(value) else { fail("parse error") }
    return value
  }
  let value = self.tokens[self.pos].to_owned()
  self.pos = self.pos + 1
  value
}

///|
fn ParseScope::take_double(
  self : ParseScope,
  min? : Double? = None,
  max? : Double? = None,
  default? : Double? = None,
) -> Double raise {
  guard self.pos < self.tokens.length() else {
    guard default is Some(value) else { fail("parse error") }
    return value
  }
  if self.tokens[self.pos] == "~" {
    self.pos = self.pos + 1
    guard default is Some(value) else { fail("parse error") }
    return value
  }
  let token = self.tokens[self.pos]
  self.pos = self.pos + 1
  @schema.query_double(token, min, max)
}

///|
fn ParseScope::take_int(
  self : ParseScope,
  min? : Int? = None,
  max? : Int? = None,
  default? : Int? = None,
) -> Int raise {
  guard self.pos < self.tokens.length() else {
    guard default is Some(value) else { fail("parse error") }
    return value
  }
  if self.tokens[self.pos] == "~" {
    self.pos = self.pos + 1
    guard default is Some(value) else { fail("parse error") }
    return value
  }
  let token = self.tokens[self.pos]
  self.pos = self.pos + 1
  @schema.query_int(token, min, max)
}

///|
fn ParseScope::take_uint(
  self : ParseScope,
  min? : UInt? = None,
  max? : UInt? = None,
  default? : UInt? = None,
) -> UInt raise {
  guard self.pos < self.tokens.length() else {
    guard default is Some(value) else { fail("parse error") }
    return value
  }
  if self.tokens[self.pos] == "~" {
    self.pos = self.pos + 1
    guard default is Some(value) else { fail("parse error") }
    return value
  }
  let token = self.tokens[self.pos]
  self.pos = self.pos + 1
  @schema.query_uint(token, min, max)
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
