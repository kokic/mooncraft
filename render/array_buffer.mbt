///|
#external
pub type ArrayBuffer

///|
pub extern "js" fn ArrayBuffer::byte_length(self : ArrayBuffer) -> Int =
  #| (buffer) => buffer.byteLength

///|
pub extern "js" fn ArrayBuffer::slice(self : ArrayBuffer, start : Int, end : Int) -> ArrayBuffer =
  #| (buffer, start, end) => buffer.slice(start, end)
