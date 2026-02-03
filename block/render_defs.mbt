///|
pub let fallback_texture : String = "missing_tile"

///|
pub fn collect_texture_names() -> Array[String] {
  let seen : Map[String, Bool] = Map::new()
  let out : Array[String] = [fallback_texture]
  seen[fallback_texture] = true
  for block in blocks {
    let faces = block.faces
    if faces.pos_x is Some(tex) && !seen.contains(tex) {
      seen[tex] = true
      out.push(tex)
    }
    if faces.neg_x is Some(tex) && !seen.contains(tex) {
      seen[tex] = true
      out.push(tex)
    }
    if faces.pos_y is Some(tex) && !seen.contains(tex) {
      seen[tex] = true
      out.push(tex)
    }
    if faces.neg_y is Some(tex) && !seen.contains(tex) {
      seen[tex] = true
      out.push(tex)
    }
    if faces.pos_z is Some(tex) && !seen.contains(tex) {
      seen[tex] = true
      out.push(tex)
    }
    if faces.neg_z is Some(tex) && !seen.contains(tex) {
      seen[tex] = true
      out.push(tex)
    }
  }
  out
}

///|
/// Collect (long_id, opacity, luminance) for lighting.
pub fn collect_block_light_info() -> Array[Array[Int]] {
  let out : Array[Array[Int]] = []
  for block in blocks {
    let long_id = block.long_id().reinterpret_as_int()
    out.push([long_id, block.opacity, block.luminance])
  }
  out
}
