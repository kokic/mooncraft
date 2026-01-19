///|
pub extern "js" fn js_console_log(v : JsValue) -> Unit = "(v) => console.log(v)"

///|
pub extern "js" fn js_console_err(v : JsValue) -> Unit = "(v) => console.err(v)"

///|
pub fn[T] console_log(v : T) -> Unit {
  js_console_log(JsValue::cast_from(v))
}

///|
pub fn[T] console_err(v : T) -> Unit {
  js_console_err(JsValue::cast_from(v))
}
