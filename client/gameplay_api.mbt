///|
/// Publish stateless block, item, placement, localization, and biome APIs.
fn register_gameplay_api(world : @level.World) -> Unit {
  publish_global(
    "mcTorchStateFromPlacement",
    @genus.Torch::torch_state_from_placement,
  )
  publish_global("mcTorchShapeBoxByState", @genus.Torch::shape_box_by_state)
  publish_global("mcCollectTextureNames", @block.collect_texture_names)
  publish_global("mcCollectBlockLightInfo", @block.collect_block_light_info)
  publish_global("mcGetLongIdByName", @block.name_to_long_id)
  publish_global("mcBlockIsSelectable", @block.Block::is_selectable)
  publish_global("mcPackLongId", @util.pack_long_id)
  publish_global("mcUnpackLongId", @util.unpack_long_id)
  publish_global("mcCanPlaceBlock", @player.can_place_block)
  publish_global("mcRaycastBlocks", @level.raycast_blocks)
  publish_global("mcGetBlockId", @level.get_block_id)
  publish_global("mcIsWaterAt", @level.is_water_at)
  publish_global("mcSetBlockId", @level.set_block_id)
  publish_global("mcBuildChunkDataPadded", @level.build_chunk_data_padded)
  publish_global("mcApplyUseOnAction", @level.apply_use_on_action_with_player)
  publish_global("mcApplyUseAction", @level.apply_use_action)
  publish_global("mcGetBlockShapeDesc", @block.get_shape_desc)
  publish_global("mcGetBlockOutlineDesc", @block.get_outline_desc)
  publish_global("mcComputePlacementState", fn(
    long_id : UInt,
    block : Array[Int],
    previous : Array[Int],
  ) -> UInt {
    @block.compute_placement_state(long_id, block, previous)
  })
  publish_global("mcUseItemOn", @item.use_item_on)
  publish_global("mcUseItem", @item.use_item)
  publish_global("mcGetItemDisplayName", @i18n.item_display_name)
  publish_global("mcGetBiomeName", fn(wx : Int, wz : Int) -> String {
    @biome.name(@biome.biome_at(world.noise, wx, wz))
  })
  publish_global("mcGetWaterTint", fn(wx : Int, wz : Int) -> Array[Double] {
    let sample = @biome.sample(world.noise, wx, wz)
    let biome = @biome.biome_from_sample(sample)
    let (r, g, b, a) = @genus.Water::tint_for_sample(biome, sample)
    [r.to_double(), g.to_double(), b.to_double(), a.to_double()]
  })
}
