///|
/// Publish stateless block, item, placement, localization, and biome APIs.
pub fn register_gameplay_api(world : @level.World) -> Unit {
  @ffi.cast_global_set(
    "mcTorchStateFromPlacement",
    @genus.Torch::torch_state_from_placement,
  )
  @ffi.cast_global_set(
    "mcTorchShapeBoxByState",
    @genus.Torch::shape_box_by_state,
  )
  @ffi.cast_global_set(
    "mcCollectBlockLightInfo", @block.collect_block_light_info,
  )
  @ffi.cast_global_set("mcGetInternalIdByName", @block.name_to_internal_id)
  @ffi.cast_global_set("mcBlockIsSelectable", @block.Block::is_selectable)
  @ffi.cast_global_set("mcCanPlaceBlock", @player.can_place_block)
  @ffi.cast_global_set("mcGetBlockShapeDesc", @block.get_shape_desc)
  @ffi.cast_global_set("mcGetBlockOutlineDesc", @block.get_outline_desc)
  @ffi.cast_global_set("mcComputePlacementState", (
    internal_id : UInt,
    block : Array[Int],
    previous : Array[Int],
  ) => @block.compute_placement_state(internal_id, block, previous))
  @ffi.cast_global_set("mcUseItemOn", @item.use_item_on)
  @ffi.cast_global_set("mcUseItem", @item.use_item)
  @ffi.cast_global_set("mcGetItemDisplayName", @i18n.item_display_name)
  @ffi.cast_global_set("mcGetBiomeName", (wx : Int, wz : Int) => {
    @biome.name(@biome.biome_at(world.noise, wx, wz))
  })
  @ffi.cast_global_set("mcGetWaterTint", (wx : Int, wz : Int) => {
    let sample = @biome.sample(world.noise, wx, wz)
    let biome = @biome.biome_from_sample(sample)
    let (r, g, b, a) = @genus.Water::tint_for_sample(biome, sample)
    [r.to_double(), g.to_double(), b.to_double(), a.to_double()]
  })
}
