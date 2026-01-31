///|
pub extern "js" fn js_map_get(map : JsValue, key : String) -> JsValue =
  #| (map, key) => map.get(key)

///|
pub extern "js" fn js_map_has(map : JsValue, key : String) -> Bool =
  #| (map, key) => map.has(key)
