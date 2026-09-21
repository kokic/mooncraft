///|
/// Execute every action at the game boundary so nested batches can mix world
/// and player effects. Preserve action order and the returned dirty chunk keys.
fn GameRuntime::apply_use_action(
  self : GameRuntime,
  action : @item.UseAction,
) -> Array[String] {
  match action {
    None => []
    Batch(actions) => {
      let dirty_chunks : Array[String] = []
      for action in actions {
        for key in self.apply_use_action(action) {
          dirty_chunks.push(key)
        }
      }
      dirty_chunks
    }
    Eat(nutrition~, saturation~) => {
      ignore(self.player_runtime.eat(nutrition, saturation))
      []
    }
    BreakBlock(..) =>
      @level.apply_use_action(
        self.chunk_runtime.chunk_map(),
        self.chunk_runtime.chunk_size,
        action,
      )
  }
}

///|
fn GameRuntime::apply_use_on_action(
  self : GameRuntime,
  action : @item.UseOnAction,
  player_pos : Array[Double],
  entity_height : Double,
  entity_radius : Double,
) -> Array[String] {
  @level.apply_use_on_action_with_player(
    self.chunk_runtime.chunk_map(),
    self.chunk_runtime.chunk_size,
    action,
    player_pos,
    entity_height,
    entity_radius,
  )
}
