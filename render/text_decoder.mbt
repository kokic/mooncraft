///|
#external
pub type TextDecoder

///|
pub extern "js" fn TextDecoder::new_utf8() -> TextDecoder =
  #| () => new TextDecoder("utf-8")

///|
pub extern "js" fn TextDecoder::decode(self : TextDecoder, buffer : ArrayBuffer) -> String =
  #| (decoder, buffer) => decoder.decode(buffer)
