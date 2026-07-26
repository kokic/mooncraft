///|
/// Publish a MoonBit value through the browser's stable `mc*` global contract.
fn[V] publish_global(name : String, value : V) -> Unit {
  @ffi.cast_global_set(name, value)
}
