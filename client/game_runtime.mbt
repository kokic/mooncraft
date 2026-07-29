///|
/// One world-runtime tick's complete output. The browser turns this into WebGL
/// resource mutations and DOM/HUD updates. It never derives world state on
/// its own.
pub struct GameFrame {
  chunk : @render.ChunkRenderFrame
  player : @player.PlayerSnapshot
  inventory : @player.PlayerInventorySnapshot
  render_distance : Int
}

///|
/// Owns the full CPU-side game runtime: chunk streaming/lighting, the player,
/// and inventory. Browser code feeds it intents and executes the commands and
/// snapshots it emits.
priv struct GameRuntime {
  world : @level.World
  chunk_runtime : @render.ChunkRuntime
  player_runtime : @player.PlayerRuntime
  chunk_size : Int
}

///|
fn GameRuntime::new(
  world : @level.World,
  chunk_runtime : @render.ChunkRuntime,
  player_runtime : @player.PlayerRuntime,
  chunk_size : Int,
) -> GameRuntime {
  { world, chunk_runtime, player_runtime, chunk_size }
}

///|
fn GameRuntime::chunk_map(self : GameRuntime) -> @ffi.JsValue {
  self.chunk_runtime.chunk_map()
}

///|
/// Encode the current world/player/inventory into an explicit save payload.
fn GameRuntime::save_snapshot(self : GameRuntime, saved_at : Double) -> String {
  @save.SavePayload::new(
    saved_at,
    self.world.seed(),
    self.world.world_type_name(),
    self.world.height(),
    self.player_runtime.position(),
    self.player_runtime.yaw(),
    self.player_runtime.pitch(),
    self.player_runtime.inventory_snapshot(),
    self.chunk_runtime.block_deltas(),
    @mob.save_entities(),
  ).encode()
}

///|
/// Resolve the chunk column containing the current player position.
fn GameRuntime::player_chunk_center(self : GameRuntime) -> (Int, Int) {
  let position = self.player_runtime.position()
  (
    @util.floor_div(position[0].to_int(), self.chunk_size),
    @util.floor_div(position[2].to_int(), self.chunk_size),
  )
}

///|
/// Advance the whole runtime one frame.
fn GameRuntime::tick(
  self : GameRuntime,
  registry : @render.BlockRegistry,
  delta : Double,
) -> GameFrame {
  let player = self.player_runtime.tick(delta)
  let (center_x, center_z) = self.player_chunk_center()
  let chunk = self.chunk_runtime.tick(
    registry,
    center_x,
    center_z,
    center_y=player.position[1].to_int(),
  )
  {
    chunk,
    player,
    inventory: self.player_runtime.inventory_snapshot(),
    render_distance: self.chunk_runtime.render_distance(),
  }
}

///|
/// Record a voxel edit already applied to the chunk map.
fn GameRuntime::mark_block_changed(
  self : GameRuntime,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Unit {
  self.chunk_runtime.mark_block_changed(wx, wy, wz)
}

///|
fn GameRuntime::player_snapshot(self : GameRuntime) -> @player.PlayerSnapshot {
  self.player_runtime.snapshot()
}

///|
fn GameRuntime::inventory_snapshot(
  self : GameRuntime,
) -> @player.PlayerInventorySnapshot {
  self.player_runtime.inventory_snapshot()
}

///|
fn GameRuntime::set_move_intent(
  self : GameRuntime,
  intent : @player.MoveInput,
) -> Unit {
  self.player_runtime.set_move_intent(intent)
}

///|
fn GameRuntime::add_look_intent(
  self : GameRuntime,
  yaw : Double,
  pitch : Double,
) -> Unit {
  self.player_runtime.add_look_intent(yaw, pitch)
}

///|
fn GameRuntime::set_game_mode(
  self : GameRuntime,
  mode : String,
) -> @player.PlayerInventorySnapshot {
  self.player_runtime.set_game_mode(mode)
}

///|
fn GameRuntime::select_hotbar(
  self : GameRuntime,
  index : Int,
) -> @player.PlayerInventorySnapshot {
  self.player_runtime.select_hotbar(index)
}

///|
fn GameRuntime::set_hotbar_slot(
  self : GameRuntime,
  index : Int,
  slot : @player.HotbarSlot?,
) -> @player.PlayerInventorySnapshot {
  self.player_runtime.set_hotbar_slot(index, slot)
}

///|
fn GameRuntime::set_inventory_open(
  self : GameRuntime,
  open : Bool,
) -> @player.PlayerInventorySnapshot {
  self.player_runtime.set_inventory_open(open)
}

///|
/// Restore full runtime state from a validated save payload.
fn GameRuntime::load_save(
  self : GameRuntime,
  payload : @save.SavePayload,
) -> Unit {
  let saved_player = payload.player()
  ignore(
    self.player_runtime.restore(
      saved_player.position(),
      saved_player.yaw(),
      saved_player.pitch(),
    ),
  )
  ignore(self.player_runtime.restore_inventory(payload.inventory()))
  for delta in payload.block_deltas() {
    self.chunk_runtime.load_block_delta(delta.x, delta.y, delta.z, delta.id)
  }
  @mob.restore_entities(payload.entities())
}
