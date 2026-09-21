///|
fn json_object(value : Json) -> Map[String, Json] {
  match value {
    Object(fields) => fields
    _ => {}
  }
}

///|
fn json_array(value : Json) -> Array[Json] {
  match value {
    Array(values) => values
    _ => []
  }
}

///|
fn json_string(value : Json, fallback? : String = "") -> String {
  match value {
    String(value) => value
    _ => fallback
  }
}

///|
fn json_double(value : Json, fallback? : Double = 0.0) -> Double {
  match value {
    Number(value, ..) => value
    _ => fallback
  }
}

///|
fn json_int(value : Json, fallback? : Int = 0) -> Int {
  json_double(value, fallback=fallback.to_double()).to_int()
}

///|
fn json_bool(value : Json, fallback? : Bool = false) -> Bool {
  match value {
    True => true
    False => false
    _ => fallback
  }
}

///|
fn json_field(fields : Map[String, Json], name : String) -> Json {
  fields.get(name).unwrap_or(Json::null())
}

///|
fn json_int_array(value : Json) -> Array[Int] {
  json_array(value).map(value => json_int(value))
}

///|
fn json_double_array(
  value : Json,
  expected : Int,
  fallback : Array[Double],
) -> Array[Double] {
  let values = json_array(value)
  guard values.length() == expected else { fallback.copy() }
  values.map(value => json_double(value))
}

///|
fn json_float32_array(
  value : Json,
  expected : Int,
  fallback : @ffi.Float32Array,
) -> @ffi.Float32Array {
  let values = json_array(value)
  guard values.length() == expected else { fallback }
  let out = @ffi.Float32Array::new(expected)
  let out_values = out.values()
  for i in 0..<expected {
    out_values[i] = json_double(values[i])
  }
  out
}
