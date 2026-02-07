///|
pub fn compute_placement_state(
  long_id : UInt,
  block : Array[Int],
  prev : Array[Int],
  player_pos? : Array[Double] = [],
) -> UInt {
  match lookup_by_long_id(long_id) {
    Some(def) =>
      match def.shape {
        shape if shape.is_torch_genus() =>
          @genus.Torch::torch_state_from_placement(block, prev)
        _ =>
          match def.facing {
            Facing::Axis => @genus.Log::log_state_from_placement(block, prev)
            Facing::Horizontal =>
              if prev.length() >= 3 {
                @genus.HorizontalFacing::state_from_player(
                  player_pos,
                  prev[0],
                  prev[2],
                )
              } else {
                def.state
              }
            Facing::Six => @genus.SixFacing::state_from_hit(block, prev)
            Facing::None => def.state
          }
      }
    None => 0
  }
}
