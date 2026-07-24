///|
pub extern "js" fn global_set(name : String, value : JsValue) -> Unit =
  #| (name, value) => { globalThis[name] = value }

///|
pub fn[V] cast_global_set(name : String, value : V) -> Unit {
  global_set(name, JsValue::cast_from(value))
}

///|
pub extern "js" fn object_has(object : JsValue, key : String) -> Bool =
  #| (object, key) => object.has(key)

///|
pub extern "js" fn object_get(object : JsValue, key : String) -> JsValue =
  #| (object, key) => object.get(key)

///|
pub extern "js" fn object_set(object : JsValue, key : String, value : JsValue) =
  #| (object, key, value) => object[key] = value

///|
pub fn[U, V] cast_object_set(object : U, key : String, value : V) -> Unit {
  object_set(JsValue::cast_from(object), key, JsValue::cast_from(value))
}

///|
/// Create a JavaScript Map for browser-facing, dynamically sized caches.
/// MoonBit runtimes own the returned map; JavaScript may only consume it.
pub extern "js" fn new_map() -> JsValue =
  #| () => new Map()

///|
pub extern "js" fn map_set(
  map : JsValue,
  key : String,
  value : JsValue,
) -> Unit =
  #| (map, key, value) => { map.set(key, value); }

///|
pub fn[V] map_set_value(map : JsValue, key : String, value : V) -> Unit {
  map_set(map, key, JsValue::cast_from(value))
}

///|
pub extern "js" fn map_delete(map : JsValue, key : String) -> Bool =
  #| (map, key) => map.delete(key)

///|
pub extern "js" fn js_console_err(v : JsValue) -> Unit =
  #| (v) => console.error(v)

///|
pub fn[T] console_err(v : T) -> Unit {
  js_console_err(JsValue::cast_from(v))
}
