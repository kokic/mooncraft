///|
pub extern "js" fn global_set(name : String, value : JsValue) -> Unit =
  #| (name, value) => { globalThis[name] = value }

///|
pub fn[V] cast_global_set(name : String, value : V) -> Unit {
  global_set(name, JsValue::cast_from(value))
}

///|
pub extern "js" fn js_console_err(v : JsValue) -> Unit =
  #| (v) => console.error(v)

///|
pub fn[T] console_err(v : T) -> Unit {
  js_console_err(JsValue::cast_from(v))
}
