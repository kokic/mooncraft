///|
#external
pub type Float32Array

///|
pub extern "js" fn Float32Array::new(length : Int) -> Float32Array =
  #| (length) => new Float32Array(length)

///|
extern "js" fn Float32Array::as_array(self : Self) -> Array[Double] =
  #| (array) => array

///|
extern "js" fn Float32Array::copy_from(
  self : Self,
  source : Float32Array,
) -> Unit =
  #| (target, source) => target.set(source)

///|
pub fn Float32Array::at(self : Self, index : Int) -> Double {
  self.as_array()[index]
}

///|
fn Float32Array::values(self : Self) -> Array[Double] {
  self.as_array()
}
