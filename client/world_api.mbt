///|
/// Block access, raycast, and block-use actions.
fn register_world_api(game : GameRuntime) -> Unit {
  @ffi.cast_global_set("mcSampleWorldLight", (
    x : Double,
    y : Double,
    z : Double,
  ) => {
    @util.light_level_scale(
      game.chunk_runtime.light_at(
        x.floor().to_int(),
        y.floor().to_int(),
        z.floor().to_int(),
      ),
    )
  })
  @ffi.cast_global_set("mcGetBlockId", (wx : Int, wy : Int, wz : Int) => {
    @level.get_block_id(
      game.chunk_runtime.chunk_map(),
      game.chunk_runtime.chunk_size,
      wx,
      wy,
      wz,
    )
  })
  @ffi.cast_global_set("mcSetBlockId", (wx : Int, wy : Int, wz : Int, id : UInt) => {
    @level.set_block_id(
      game.chunk_runtime.chunk_map(),
      game.chunk_runtime.chunk_size,
      wx,
      wy,
      wz,
      id,
    )
  })
  @ffi.cast_global_set("mcIsWaterAt", (wx : Int, wy : Int, wz : Int) => {
    @level.is_water_at(
      game.chunk_runtime.chunk_map(),
      game.chunk_runtime.chunk_size,
      wx,
      wy,
      wz,
    )
  })
  @ffi.cast_global_set("mcRaycastBlocks", (
    origin : Array[Double],
    dir : Array[Double],
    max_dist : Double,
    air_id : UInt,
    include_liquid_hit : Bool,
  ) => {
    @level.raycast_blocks(
      game.chunk_runtime.chunk_map(),
      game.chunk_runtime.chunk_size,
      origin,
      dir,
      max_dist,
      air_id,
      include_liquid_hit,
    )
  })
  @ffi.cast_global_set("mcApplyUseAction", (action : @item.UseAction) => {
    game.apply_use_action(action)
  })
  @ffi.cast_global_set("mcApplyUseOnAction", (
    action : @item.UseOnAction,
    player_pos : Array[Double],
    entity_height : Double,
    entity_radius : Double,
  ) => {
    game.apply_use_on_action(
      action,
      player_pos,
      entity_height,
      entity_radius,
    )
  })
}
