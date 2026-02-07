///|
#external
pub type JsValue

///|
pub extern "js" fn JsValue::undefined() -> JsValue =
  #| () => undefined

///|
pub extern "js" fn JsValue::is_undefined(self : Self) -> Bool =
  #| (v) => v === undefined
  #|

///|
pub extern "js" fn JsValue::null() -> JsValue =
  #| () => null

///|
pub extern "js" fn JsValue::is_null(self : Self) -> Bool =
  #| (v) => v === null

///|
pub extern "js" fn JsValue::as_string(self : JsValue) -> String =
  #| (self) =>
  #|   self === undefined ? 'undefined'
  #|     : self === null ? 'null'
  #|     : self.toString()

///|
pub extern "js" fn JsValue::unsafe_as_string(self : JsValue) -> String =
  #| (self) => self.toString()

///|
pub extern "js" fn JsValue::to_json_string(self : JsValue) -> String =
  #| (self) => JSON.stringify(self)

///|
pub impl Show for JsValue with output(self, logger) -> Unit {
  logger.write_string(self.to_json_string())
}

///|
pub fn[T] cast_to_json_string(value : T) -> String {
  JsValue::cast_from(value).to_json_string()
}

///|
pub fn[T] JsValue::cast_from(value : T) -> JsValue = "%identity"

///|
pub fn[T] JsValue::cast_to(self : Self) -> T = "%identity"

///|
pub fn[A, B] cast(a : A) -> B = "%identity"

///|
/// Also see: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is
pub extern "js" fn JsValue::equal(a : JsValue, b : JsValue) -> Bool =
  #| (a, b) => Object.is(a, b)

///|
pub impl Eq for JsValue with equal(self, other) -> Bool {
  JsValue::equal(self, other)
}

///|
extern "js" fn JsValue::raw_get(self : Self, key : Self) -> Self = "(obj, key) => obj[key]"

///|
pub fn[T] JsValue::get(self : Self, key : String) -> T {
  self.raw_get(JsValue::cast_from(key)).cast_to()
}
