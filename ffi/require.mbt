///|
pub extern "js" fn js_require(path : String) -> JsValue = "(path) => require(path)"

///|
pub fn require(path : String, keys? : Array[String] = []) -> JsValue {
  keys.fold(init=require(path), JsValue::get)
}
