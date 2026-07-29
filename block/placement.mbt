///|
pub fn compute_placement_state(
  internal_id : UInt,
  block : Array[Int],
  prev : Array[Int],
  player_pos? : Array[Double] = [],
) -> UInt {
  lookup_by_internal_id(internal_id)
  .map(def => {
    (def.profile().placement_state)(def.state, block, prev, player_pos)
  })
  .unwrap_or(0)
}
