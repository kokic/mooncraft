///|
pub let hotbar_blocks : Array[@block.Block] = [
  // @block.stone,
  // @block.tnt, 
  // @block.oak_log, 
  // @block.block_grass,
  // @block.block_dirt,
  // @block.block_sand,
  // @block.carved,
  // @block.torch_blocks[0],
  // @block.redstone_torch_blocks[0],
  // @block.redstone_torch_classic_blocks[0],
  // @block.soul_torch_blocks[0],
  // @block.copper_torch_blocks[0],
]

///|
pub fn collect_hotbar_defs() -> Array[UiItem] {
  hotbar_blocks.map(block_to_ui_def)
}
