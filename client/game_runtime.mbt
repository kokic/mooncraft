///|
/// Autosave cadence owned by MoonBit. JS only executes the resulting write.
const SAVE_THROTTLE_MS : Double = 1500.0

///|
/// One world-runtime tick's complete output. The browser turns this into WebGL
/// resource mutations, DOM/HUD updates, and (when `save` is present) a single
/// `localStorage` write. It never derives world state on its own.
pub struct GameFrame {
  chunk : @render.ChunkRenderFrame
  player : @player.PlayerSnapshot
  inventory : @player.PlayerInventorySnapshot
  save : String?
}

///|
/// Owns the full CPU-side game runtime: chunk streaming/lighting, the player,
/// and autosave scheduling. Browser code feeds it intents and executes the
/// commands and snapshots it emits.
priv struct GameRuntime {
  world : @level.World
  chunk_runtime : @render.ChunkRuntime
  player_runtime : @player.PlayerRuntime
  chunk_size : Int
  mut save_dirty : Bool
  mut last_saved_at : Double
  mut last_motion_probe_at : Double
  mut motion_key : String
}

///|
/// Quantized player pose used to detect a meaningful autosave-worthy change
/// between frames, mirroring the precision the JS fingerprint used to apply.
fn player_save_motion_key(runtime : @player.PlayerRuntime) -> String {
  let pos = runtime.position()
  let px = (pos[0] * 100.0).to_int()
  let py = (pos[1] * 100.0).to_int()
  let pz = (pos[2] * 100.0).to_int()
  let yaw = (runtime.yaw() * 1000.0).to_int()
  let pitch = (runtime.pitch() * 1000.0).to_int()
  "\{px},\{py},\{pz}:\{yaw}:\{pitch}"
}

///|
fn GameRuntime::new(
  world : @level.World,
  chunk_runtime : @render.ChunkRuntime,
  player_runtime : @player.PlayerRuntime,
  chunk_size : Int,
) -> GameRuntime {
  {
    world,
    chunk_runtime,
    player_runtime,
    chunk_size,
    // Start dirty so the first eligible tick persists the freshly spawned world.
    save_dirty: true,
    last_saved_at: 0.0,
    last_motion_probe_at: 0.0,
    motion_key: player_save_motion_key(player_runtime),
  }
}

///|
fn GameRuntime::chunk_map(self : GameRuntime) -> @ffi.JsValue {
  self.chunk_runtime.chunk_map()
}

///|
fn GameRuntime::mark_save_dirty(self : GameRuntime) -> Unit {
  self.save_dirty = true
}

///|
/// Encode the current world/player/inventory into a save payload string.
fn GameRuntime::encode_save_snapshot(
  self : GameRuntime,
  saved_at : Double,
) -> String {
  @save.SavePayload::new(
    saved_at,
    self.world.seed(),
    self.world.world_type_name(),
    self.player_runtime.position(),
    self.player_runtime.yaw(),
    self.player_runtime.pitch(),
    self.player_runtime.inventory_snapshot(),
    self.chunk_runtime.block_deltas(),
  ).encode()
}

///|
/// Decide whether an autosave should be flushed this frame, honoring throttle.
fn GameRuntime::take_autosave(self : GameRuntime, now : Double) -> String? {
  guard self.save_dirty else { None }
  guard now - self.last_saved_at >= SAVE_THROTTLE_MS else { None }
  self.save_dirty = false
  self.last_saved_at = now
  Some(self.encode_save_snapshot(now))
}

///|
/// Mark the save dirty when the quantized player pose changes. Sampling is
/// intentionally less frequent than frame updates.
fn GameRuntime::observe_player_motion(self : GameRuntime, now : Double) -> Unit {
  guard now - self.last_motion_probe_at >= 5000.0 else { () }
  self.last_motion_probe_at = now
  let motion_key = player_save_motion_key(self.player_runtime)
  guard motion_key != self.motion_key else { () }
  self.motion_key = motion_key
  self.mark_save_dirty()
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
/// Advance the whole runtime one frame. `delta` is the player integration step;
/// `now` is browser wall-clock (ms) used only for autosave throttling.
fn GameRuntime::tick(
  self : GameRuntime,
  registry : @render.BlockRegistry,
  delta : Double,
  now : Double,
) -> GameFrame {
  let player = self.player_runtime.tick(delta)
  self.observe_player_motion(now)
  let (center_x, center_z) = self.player_chunk_center()
  let chunk = self.chunk_runtime.tick(registry, center_x, center_z)
  {
    chunk,
    player,
    inventory: self.player_runtime.inventory_snapshot(),
    save: self.take_autosave(now),
  }
}

///|
/// Force-encode the current state and clear the dirty flag. Used by the browser
/// on unload to guarantee the latest frame is persisted regardless of throttle.
fn GameRuntime::flush_save(self : GameRuntime, now : Double) -> String {
  self.save_dirty = false
  self.last_saved_at = now
  self.encode_save_snapshot(now)
}

///|
/// Record a voxel edit already applied to the chunk map and mark autosave.
fn GameRuntime::mark_block_changed(
  self : GameRuntime,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Unit {
  self.chunk_runtime.mark_block_changed(wx, wy, wz)
  self.mark_save_dirty()
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
  let snapshot = self.player_runtime.set_game_mode(mode)
  self.mark_save_dirty()
  snapshot
}

///|
fn GameRuntime::select_hotbar(
  self : GameRuntime,
  index : Int,
) -> @player.PlayerInventorySnapshot {
  let snapshot = self.player_runtime.select_hotbar(index)
  self.mark_save_dirty()
  snapshot
}

///|
fn GameRuntime::set_hotbar_slot(
  self : GameRuntime,
  index : Int,
  slot : @player.HotbarSlot?,
) -> @player.PlayerInventorySnapshot {
  let snapshot = self.player_runtime.set_hotbar_slot(index, slot)
  self.mark_save_dirty()
  snapshot
}

///|
fn GameRuntime::set_inventory_open(
  self : GameRuntime,
  open : Bool,
) -> @player.PlayerInventorySnapshot {
  let snapshot = self.player_runtime.set_inventory_open(open)
  self.mark_save_dirty()
  snapshot
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
  self.motion_key = player_save_motion_key(self.player_runtime)
}
