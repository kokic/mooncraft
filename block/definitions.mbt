///|
pub let blocks : Array[Block] = [
  // Basic
  Block::create(
    "air",
    [],
    opacity=Cutout,
    shape=Shape::Air,
    category=@item.None,
  ),
  Block::create("stone", ["stone"]),
  Block::create("bedrock", ["bedrock"]),
  Block::create("obsidian", ["obsidian"]),
  Block::create("classic.obsidian", ["classic/obsidian"]),
  Block::create("crying_obsidian", ["crying_obsidian"]),
  Block::create("glowing_obsidian", ["pre-classic/glowing_obsidian"]),

  // Land
  Block::create("dirt", ["dirt"]),
  Block::create("grass", ["grass_carried", "dirt", "grass_side_carried"]),
  Block::create(
    "grass_path",
    ["grass_path_top", "dirt", "grass_path_side"],
    shape=Shape::GrassPath,
    opacity=Cutout,
  ),
  Block::create("pre-classic.grass", [
    "pre-classic/grass_carried", "dirt", "grass_side_carried",
  ]),
  Block::create("cobblestone", ["cobblestone"]),
  Block::create("pre-classic.cobblestone", ["pre-classic/cobblestone"]),

  // Artifact
  Block::create("bricks", ["bricks"]),
  ..Block::create_with_classic("gold_block", ["gold_block"]),

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
  ..Block::create_with_classic(
    "cactus",
    ["cactus_top", "cactus_bottom", "cactus_side"],
    shape=Shape::Cactus,
    opacity=Cutout,
  ),
  Block::create("glass", ["glass"], opacity=Cutout),
  Block::create("tnt", ["tnt_top", "tnt_bottom", "tnt_side"]),

  // Trees
  ..create_log_group("oak_log", ["oak_log_top", "oak_log"]),
  ..Block::create_with_classic(
    "oak_leaves",
    ["oak_leaves"],
    material=Material::TintedLeaf,
    opacity=Cutout,
  ),

  // Nether
  Block::create("netherrack", ["netherrack"]),

  // Miscellaneous
  Block::create("redstone_block", ["redstone_block"]),
  ..create_torch_group("torch", ["torch"], Shape::Torch, luminance=14),
  ..create_torch_group(
    "redstone_torch",
    ["redstone_torch"],
    Shape::RedstoneTorch,
    luminance=7,
  ),
  ..create_torch_group(
    "classic.redstone_torch",
    ["classic/redstone_torch"],
    Shape::RedstoneTorchClassic,
    luminance=7,
  ),
  ..create_torch_group("soul_torch", ["soul_torch"], Shape::Torch, luminance=14),
  ..create_torch_group(
    "copper_torch",
    ["copper_torch"],
    Shape::Torch,
    luminance=14,
  ),
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
  luminance? : Int = 0,
  category? : @item.Category = @item.Item,
) -> Block {
  Block::create(
    @genus.Torch::unique_name(base, state),
    opacity=Cutout,
    luminance~,
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
  luminance? : Int = 0,
) -> Array[Block] {
  [
    create_torch(base, id, 0, faces, shape, luminance~),
    create_torch(base, id, 1, faces, shape, luminance~, category=@item.None),
    create_torch(base, id, 2, faces, shape, luminance~, category=@item.None),
    create_torch(base, id, 3, faces, shape, luminance~, category=@item.None),
    create_torch(base, id, 4, faces, shape, luminance~, category=@item.None),
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

///|
fn Block::create_with_classic(
  name : @util.UniqueName,
  state? : UInt = 0,
  opacity? : Opacity = Opacity::Solid,
  luminance? : Int = 0,
  shape? : Shape = Shape::Cube,
  material? : Material = Material::Normal,
  category? : @item.Category = @item.Block,
  faces : FixedArray[String],
) -> Array[Block] {
  [
    Block::create(
      id=alloc_id(),
      name,
      state~,
      opacity~,
      luminance~,
      shape~,
      material~,
      category~,
      faces,
    ),
    Block::create(
      id=alloc_id(),
      "classic." + name,
      state~,
      opacity~,
      luminance~,
      shape~,
      material~,
      category~,
      faces.map(s => "classic/" + s),
    ),
  ]
}
