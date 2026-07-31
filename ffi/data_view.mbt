///|
#external
pub type DataView

///|
pub extern "js" fn DataView::new(buffer : ArrayBuffer) -> DataView =
  #| (buffer) => new DataView(buffer)

///|
pub extern "js" fn DataView::byte_length(self : DataView) -> Int =
  #| (view) => view.byteLength

///|
pub extern "js" fn DataView::get_uint8(self : DataView, offset : Int) -> Int =
  #| (view, offset) => view.getUint8(offset)

///|
pub extern "js" fn DataView::get_uint32_le(
  self : DataView,
  offset : Int,
) -> Int =
  #| (view, offset) => view.getUint32(offset, true)

///|
pub extern "js" fn DataView::get_int8(self : DataView, offset : Int) -> Int =
  #| (view, offset) => view.getInt8(offset)

///|
pub extern "js" fn DataView::get_int16_le(self : DataView, offset : Int) -> Int =
  #| (view, offset) => view.getInt16(offset, true)

///|
pub extern "js" fn DataView::get_uint16_le(
  self : DataView,
  offset : Int,
) -> Int =
  #| (view, offset) => view.getUint16(offset, true)

///|
pub extern "js" fn DataView::get_uint32(self : DataView, offset : Int) -> Int =
  #| (view, offset) => view.getUint32(offset, true)

///|
pub extern "js" fn DataView::get_float32_le(
  self : DataView,
  offset : Int,
) -> Double =
  #| (view, offset) => view.getFloat32(offset, true)
