///|
pub fn compute_placement_state(
  long_id : UInt,
  block : Array[Int],
  prev : Array[Int],
  player_pos? : Array[Double] = [],
) -> UInt {
  lookup_by_long_id(long_id)
  .map(def => {
    (def.profile().placement_state)(def.state, block, prev, player_pos)
  })
  .unwrap_or(0)
}
