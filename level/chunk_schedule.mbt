///|
/// Collect chunk keys for render distance around the center chunk.
/// The iteration order matches JS-side scheduling for predictable caching.
pub fn collect_render_chunk_keys(
  center_x : Int,
  center_z : Int,
  render_distance : Int,
  chunk_min_y : Int,
  chunk_max_y : Int,
) -> Array[String] {
  let keys : Array[String] = []
  for ring in 0..<=render_distance {
    for dx in -ring..<=ring {
      for dz in -ring..<=ring {
        if dx.abs() != ring && dz.abs() != ring {
          continue
        }
        for cy in chunk_min_y..<=chunk_max_y {
          keys.push(chunk_key_by_chunk_xyz(center_x + dx, cy, center_z + dz))
        }
      }
    }
  }
  keys
}
