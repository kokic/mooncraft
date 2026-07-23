///|
extern "js" fn fetch_array_buffer(
  url : String,
  on_load : (ArrayBuffer) -> Unit,
  on_error : (String) -> Unit,
) -> Unit =
  #| (url, onLoad, onError) => {
  #|   fetch(new URL(url, globalThis.location.href), { cache: "no-store" })
  #|     .then((response) => {
  #|       if (!response.ok) throw new Error(`HTTP ${response.status} for ${url}`);
  #|       return response.arrayBuffer();
  #|     })
  #|     .then(onLoad, (error) => onError(String(error?.stack ?? error)));
  #| }

///|
extern "js" fn load_image_url(
  url : String,
  on_load : (@ffi.JsValue) -> Unit,
  on_error : (String) -> Unit,
) -> Unit =
  #| (url, onLoad, onError) => {
  #|   const image = new Image();
  #|   image.onload = () => onLoad(image);
  #|   image.onerror = () => onError(`failed to load image: ${url}`);
  #|   image.src = new URL(url, globalThis.location.href).href;
  #| }

///|
extern "js" fn load_image_buffer(
  buffer : ArrayBuffer,
  mime_type : String,
  on_load : (@ffi.JsValue) -> Unit,
  on_error : (String) -> Unit,
) -> Unit =
  #| (buffer, mimeType, onLoad, onError) => {
  #|   const objectUrl = URL.createObjectURL(new Blob([buffer], { type: mimeType }));
  #|   const image = new Image();
  #|   image.onload = () => {
  #|     URL.revokeObjectURL(objectUrl);
  #|     onLoad(image);
  #|   };
  #|   image.onerror = () => {
  #|     URL.revokeObjectURL(objectUrl);
  #|     onError(`failed to decode ${mimeType} image`);
  #|   };
  #|   image.src = objectUrl;
  #| }

///|
extern "js" fn decode_data_uri(uri : String) -> ArrayBuffer =
  #| (uri) => {
  #|   const comma = uri.indexOf(",");
  #|   if (comma < 0) throw new Error("invalid data URI");
  #|   const metadata = uri.slice(0, comma);
  #|   const payload = uri.slice(comma + 1);
  #|   if (metadata.endsWith(";base64")) {
  #|     const raw = atob(payload);
  #|     const bytes = new Uint8Array(raw.length);
  #|     for (let i = 0; i < raw.length; i += 1) bytes[i] = raw.charCodeAt(i);
  #|     return bytes.buffer;
  #|   }
  #|   return new TextEncoder().encode(decodeURIComponent(payload)).buffer;
  #| }

///|
extern "js" fn resolve_asset_url(base_url : String, uri : String) -> String =
  #| (baseUrl, uri) => new URL(uri, baseUrl).href

///|
extern "js" fn absolute_asset_url(url : String) -> String =
  #| (url) => new URL(url, globalThis.location.href).href

///|
extern "js" fn array_buffer_to_text(buffer : ArrayBuffer) -> String =
  #| (buffer) => new TextDecoder("utf-8").decode(buffer)

///|
fn is_data_uri(uri : String) -> Bool {
  uri.length() >= 5 && uri[:5].to_owned() == "data:"
}

///|
fn is_glb_buffer(buffer : ArrayBuffer) -> Bool {
  buffer.byte_length() >= 4 &&
  DataView::new(buffer).get_uint32_le(0) == 0x46546c67
}
