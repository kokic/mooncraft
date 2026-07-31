///|
#external
pub type Float32Array

///|
pub extern "js" fn Float32Array::new(length : Int) -> Float32Array =
  #| (length) => new Float32Array(length)

///|
pub extern "js" fn Float32Array::as_array(self : Self) -> Array[Double] =
  #| (array) => array

///|
pub extern "js" fn Float32Array::copy_from(
  self : Self,
  source : Float32Array,
) -> Unit =
  #| (target, source) => target.set(source)

///|
pub extern "js" fn Float32Array::length(self : Self) -> Int =
  #| (array) => array.length

///|
pub fn Float32Array::at(self : Self, index : Int) -> Double {
  self.as_array()[index]
}

///|
pub fn Float32Array::values(self : Self) -> Array[Double] {
  self.as_array()
}
