///|
pub fn compute_placement_state(
  long_id : UInt,
  block : Array[Int],
  prev : Array[Int],
) -> UInt {
  match lookup_by_long_id(long_id) {
    Some(def) =>
      match def.shape {
        shape if shape.is_torch_genus() =>
          @genus.Torch::torch_state_from_placement(block, prev)
        Shape::Log => @genus.Log::log_state_from_placement(block, prev)
        _ => def.state
      }
    None => 0
  }
}
