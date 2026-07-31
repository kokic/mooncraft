///|
#external
pub type Uint8Array

///|
pub extern "js" fn Uint8Array::new(length : Int) -> Uint8Array =
  #| (length) => new Uint8Array(length)

///|
pub extern "js" fn Uint8Array::from_buffer(buffer : ArrayBuffer) -> Uint8Array =
  #| (buffer) => new Uint8Array(buffer)

///|
pub extern "js" fn Uint8Array::length(self : Uint8Array) -> Int =
  #| (array) => array.length

///|
pub extern "js" fn Uint8Array::get(self : Uint8Array, index : Int) -> Int =
  #| (array, index) => array[index]

///|
pub extern "js" fn Uint8Array::buffer(self : Uint8Array) -> ArrayBuffer =
  #| (array) => array.buffer

///|
#external
pub type Uint16Array

///|
pub extern "js" fn Uint16Array::new(length : Int) -> Uint16Array =
  #| (length) => new Uint16Array(length)

///|
pub extern "js" fn Uint16Array::length(self : Uint16Array) -> Int =
  #| (array) => array.length

///|
pub extern "js" fn Uint16Array::get(self : Uint16Array, index : Int) -> Int =
  #| (array, index) => array[index]

///|
#external
pub type Uint32Array

///|
pub extern "js" fn Uint32Array::new(length : Int) -> Uint32Array =
  #| (length) => new Uint32Array(length)

///|
pub extern "js" fn Uint32Array::length(self : Uint32Array) -> Int =
  #| (array) => array.length

///|
pub extern "js" fn Uint32Array::get(self : Uint32Array, index : Int) -> Int =
  #| (array, index) => array[index]

///|
pub fn typed_array_to_floats(ua : Uint8Array) -> Array[Float] {
  let len = ua.length()
  let out : Array[Float] = []
  for i in 0..<len {
    out.push(Float::from_int(ua.get(i)))
  }
  out
}
