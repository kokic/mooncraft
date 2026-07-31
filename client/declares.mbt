///|
/// One world-runtime tick's complete output. The browser turns this into WebGL
/// resource mutations and DOM/HUD updates. It never derives world state on
/// its own.
pub struct GameFrame {
  chunk : @chunk.ChunkRenderFrame
  player : @player.PlayerSnapshot
  inventory : @player.PlayerInventorySnapshot
  render_distance : Int
}

///|
/// Owns the full CPU-side game runtime: chunk streaming/lighting, the player,
/// and inventory. Browser code feeds it intents and executes the commands and
/// snapshots it emits.
pub struct GameRuntime {
  world : @level.World
  chunk_runtime : @chunk.ChunkRuntime
  player_runtime : @player.PlayerRuntime
  chunk_size : Int
}
