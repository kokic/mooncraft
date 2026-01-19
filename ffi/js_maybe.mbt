///|
#external
pub type JsMaybe[_] // T | undefined | null

///|
pub fn[T] JsMaybe::undefined() -> JsMaybe[T] {
  JsValue::undefined().cast_to()
}

///|
pub fn[T] JsMaybe::is_undefined(self : JsMaybe[T]) -> Bool {
  self |> JsValue::cast_from |> JsValue::is_undefined
}

///|
pub fn[T] JsMaybe::null() -> JsMaybe[T] {
  JsValue::null().cast_to()
}

///|
pub fn[T] JsMaybe::is_null(self : JsMaybe[T]) -> Bool {
  self |> JsValue::cast_from |> JsValue::is_null
}

///|
pub fn[T] JsMaybe::unwrap(self : Self[T]) -> T {
  guard !self.is_undefined() else {
    abort("Cannot unwrap an undefined or null")
  }
  JsValue::cast_from(self).cast_to()
}

///|
pub fn[T] JsMaybe::to_option(self : JsMaybe[T]) -> T? {
  let casted = JsValue::cast_from(self)
  guard !(casted.is_undefined() || casted.is_null()) else { None }
  Some(casted.cast_to())
}

///|
pub fn[T] JsMaybe::from_option(
  value : T?,
  none? : JsMaybe[T] = JsMaybe::null(),
) -> JsMaybe[T] {
  guard value is Some(v) else { none }
  JsValue::cast_from(v).cast_to()
}
