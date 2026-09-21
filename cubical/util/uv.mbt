///|
pub fn rect_uv_pixels(
  start_x : Float,
  start_y : Float,
  end_x : Float,
  end_y : Float,
  texture_size? : Float = 16.0F,
) -> (Float, Float, Float, Float) {
  (
    start_x / texture_size,
    start_y / texture_size,
    (end_x + 1) / texture_size,
    (end_y + 1) / texture_size,
  )
}

///|
pub fn offset_uv_pixels(
  offset_x : Float,
  offset_y : Float,
  width : Float,
  height : Float,
  texture_size? : Float = 16.0F,
) -> (Float, Float, Float, Float) {
  (
    offset_x / texture_size,
    offset_y / texture_size,
    (offset_x + width) / texture_size,
    (offset_y + height) / texture_size,
  )
}
