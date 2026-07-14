///|
/// Capture runtime state from JS side if available.
pub extern "js" fn capture_runtime_state_raw() -> JsValue =
  #| () =>
  #|   typeof globalThis.mcCaptureRuntimeState === "function"
  #|     ? globalThis.mcCaptureRuntimeState()
  #|     : undefined

///|
/// Apply runtime state on JS side if available.
pub extern "js" fn apply_runtime_state_raw(state : JsValue) -> Bool =
  #| (state) =>
  #|   typeof globalThis.mcApplyRuntimeState === "function"
  #|     ? !!globalThis.mcApplyRuntimeState(state)
  #|     : false

///|
/// Capture runtime state as raw JsValue.
pub fn runtime_state_snapshot() -> JsValue? {
  let value = capture_runtime_state_raw()
  guard !value.is_undefined() && !value.is_null() else { None }
  Some(value)
}

///|
/// Capture runtime state and cast to a target MoonBit type.
pub fn[T] runtime_state_snapshot_as() -> T? {
  runtime_state_snapshot().map(value => value.cast_to())
}

///|
/// Apply a MoonBit value to JS runtime state.
pub fn[T] apply_runtime_state(state : T) -> Bool {
  apply_runtime_state_raw(JsValue::cast_from(state))
}
