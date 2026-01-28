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

///|
pub extern "js" fn define_custom_elements(name : String) -> Unit =
  #| (name) => customElements.define(name, class extends HTMLElement {
  #|     
  #| });

///|
pub extern "js" fn set_global_value(name : String, value : JsValue) -> Unit =
  #| (name, value) => { globalThis[name] = value }
