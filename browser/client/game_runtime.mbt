///|
/// Advance the whole runtime one frame.
fn GameRuntime::tick(
  self : GameRuntime,
  registry : @block.RenderRegistry,
  delta : Double,
) -> GameFrame {
  let player = self.player_runtime.tick(delta)
  let player_y = player.position[1].floor().to_int()
  let address = @level.BlockAddress::new(
    self.chunk_runtime.chunk_size,
    player.position[0].floor().to_int(),
    player_y,
    player.position[2].floor().to_int(),
  )
  let chunk = self.chunk_runtime.tick(
    registry,
    address.cx,
    address.cz,
    center_y=player_y,
  )
  {
    chunk,
    player,
    inventory: self.player_runtime.inventory_snapshot(),
    render_distance: self.chunk_runtime.render_distance(),
  }
}
