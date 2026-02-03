///|
#external
pub type Document

///|
#external
pub type Element

///|
#external
pub type WebGL2RenderingContext

///|
pub extern "js" fn get_webgl2_ctx() -> JsMaybe[WebGL2RenderingContext] =
  #| () => document.createElement("canvas").getContext("webgl2")
