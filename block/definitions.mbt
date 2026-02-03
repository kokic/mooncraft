///|
pub let blocks : Array[Block] = [
  // Basic
  Block::create("air", opacity=0, shape=Shape::Air, [], category=@item.None),
  Block::create("stone", ["stone"]),
  Block::create("bedrock", ["bedrock"]),

  // Land
  Block::create("dirt", ["dirt"]),
  Block::create("grass", ["grass_carried", "dirt", "grass_side_carried"]),
  Block::create("pre-classic.grass", [
    "pre-classic/grass_carried", "dirt", "grass_side_carried",
  ]),
  Block::create("cobblestone", ["cobblestone"]),
  Block::create("pre-classic.cobblestone", ["pre-classic/cobblestone"]),

  // Desert
  Block::create("sand", ["sand"]),
  Block::create("sandstone", [
    "sandstone_top", "sandstone_bottom", "sandstone_normal",
  ]),
  Block::create("sandstone_carved", [
    "sandstone_top", "sandstone_bottom", "sandstone_carved",
  ]),
  Block::create("sandstone_smooth", [
    "sandstone_top", "sandstone_bottom", "sandstone_smooth",
  ]),
  Block::create("glass", ["glass"]),
  Block::create("tnt", ["tnt_top", "tnt_bottom", "tnt_side"]),

  // Trees
  ..create_log_group("oak_log", ["oak_log_top", "oak_log"]),
  Block::create("oak_leaves", ["oak_leaves"], material=Material::TintedLeaf),
  Block::create(
    "classic.oak_leaves",
    ["classic/oak_leaves"],
    material=Material::TintedLeaf,
  ),

  // Nether
  Block::create("netherrack", ["netherrack"]),

  // Miscellaneous
  ..create_torch_group("torch", ["torch"], Shape::Torch),
  ..create_torch_group(
    "redstone_torch",
    ["redstone_torch"],
    Shape::RedstoneTorch,
  ),
  ..create_torch_group(
    "classic.redstone_torch",
    ["classic/redstone_torch"],
    Shape::RedstoneTorchClassic,
  ),
  ..create_torch_group("soul_torch", ["soul_torch"], Shape::Torch),
  ..create_torch_group("copper_torch", ["copper_torch"], Shape::Torch),
]

///|
/// The long id of the air block should be an invariant
pub const AIR_LONG_ID : UInt = 0 // block_air.long_id()

///|
pub fn Block::is_air(block : Block) -> Bool {
  block.id == AIR_LONG_ID
}

///|
fn create_torch(
  base : String,
  id : UInt,
  state : UInt,
  faces : FixedArray[String],
  shape : Shape,
  category? : @item.Category = @item.Item,
) -> Block {
  Block::create(
    @genus.Torch::unique_name(base, state),
    id~,
    state~,
    shape~,
    category~,
    faces,
  )
}

///|
fn create_torch_group(
  base : String,
  id? : UInt = alloc_id(),
  faces : FixedArray[String],
  shape : Shape,
) -> Array[Block] {
  [
    create_torch(base, id, 0, faces, shape),
    create_torch(base, id, 1, faces, shape, category=@item.None),
    create_torch(base, id, 2, faces, shape, category=@item.None),
    create_torch(base, id, 3, faces, shape, category=@item.None),
    create_torch(base, id, 4, faces, shape, category=@item.None),
  ]
}

///|
fn create_log(
  base : String,
  id : UInt,
  state : UInt,
  faces : FixedArray[String],
  category? : @item.Category = @item.Item,
) -> Block {
  Block::create(
    @genus.Log::unique_name(base, state),
    id~,
    state~,
    shape=Shape::Log,
    category~,
    faces,
  )
}

///|
fn create_log_group(
  base : String,
  id? : UInt = alloc_id(),
  faces : FixedArray[String],
) -> Array[Block] {
  [
    create_log(base, id, 0, faces),
    create_log(base, id, 1, faces, category=@item.None),
    create_log(base, id, 2, faces, category=@item.None),
  ]
}
