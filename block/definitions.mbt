///|
pub let blocks : Array[Block] = [
  // Basic
  Block::create(
    "air",
    [],
    opacity=0,
    alpha_mode=AlphaMode::Cutout,
    occlusion_cull=false,
    shape=Shape::Air,
    category=@item.None,
  ),
  Block::create("stone", ["stone"]),
  Block::create("bedrock", ["bedrock"]),
  Block::create("obsidian", ["obsidian"]),
  Block::create("classic.obsidian", ["classic/obsidian"]),
  Block::create("crying_obsidian", ["crying_obsidian"]),
  Block::create("glowing_obsidian", ["pre-classic/glowing_obsidian"]),

  // Terrain
  Block::create("grass_snow", ["snow", "dirt", "grass_side_snowed"]),
  Block::create("classoc.grass_snow", [
    "classic/snow", "dirt", "classic/grass_side_snowed",
  ]),
  ..[
    "snow", "gravel", "ice", "coal_ore", "iron_ore", "gold_ore", "diamond_ore", "lapis_ore",
    "redstone_ore", "emerald_ore",
  ].map(v => Block::create("classic." + v, ["classic/" + v])),
  Block::create("clay", ["clay"]),

  // Land
  Block::create("dirt", ["dirt"]),
  Block::create("grass", ["grass_carried", "dirt", "grass_side_carried"]),
  Block::create(
    "grass_path",
    ["grass_path_top", "dirt", "grass_path_side"],
    shape=Shape::GrassPath,
    occlusion_cull=false,
    opacity=14,
    alpha_mode=AlphaMode::Opaque,
  ),
  Block::create("pre-classic.grass", [
    "pre-classic/grass_carried", "dirt", "grass_side_carried",
  ]),
  Block::create("cobblestone", ["cobblestone"]),
  Block::create("pre-classic.cobblestone", ["pre-classic/cobblestone"]),

  // Liquid
  Block::create(
    "water",
    ["water_still"],
    shape=Shape::Liquid,
    occlusion_cull=false,
    same_block_cull=true,
    alpha_mode=AlphaMode::Translucent,
    material=Material::Normal,
  ),
  Block::create(
    "lava",
    ["pre-classic/lava_still"],
    shape=Shape::Liquid,
    occlusion_cull=false,
    same_block_cull=true,
    alpha_mode=AlphaMode::Cutout,
    luminance=15,
  ),

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
    occlusion_cull=false,
    opacity=0,
    alpha_mode=AlphaMode::Cutout,
  ),
  Block::create(
    "glass",
    ["glass"],
    occlusion_cull=false,
    same_block_cull=true,
    opacity=0,
    alpha_mode=AlphaMode::Cutout,
  ),
  Block::create("tnt", ["tnt_top", "tnt_bottom", "tnt_side"]),

  // Trees
  ..["oak", "dark_oak", "birch", "acacia", "jungle", "spruce"]
  .map(v => create_log_group("classic.\{v}_log", [
    "classic/\{v}_log_top",
    "classic/\{v}_log",
  ]))
  .flatten(),
  ..Block::create_with_classic(
    "oak_leaves",
    ["oak_leaves"],
    material=Material::TintedLeaf,
    occlusion_cull=false,
    same_block_cull=false,
    opacity=0,
    alpha_mode=AlphaMode::Opaque,
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
/// True if the block should be selectable (outlined box) in UI.
pub fn Block::is_selectable(block : Block) -> Bool {
  match block.shape {
    Air | Liquid => false
    _ => true
  }
}

///|
fn create_torch(
  base : String,
  id : UInt,
  state : UInt,
  faces : FixedArray[String],
  shape : Shape,
  luminance? : Int = 0,
  category? : @item.Category = @item.Block,
) -> Block {
  Block::create(
    @genus.Torch::unique_name(base, state),
    occlusion_cull=false,
    alpha_mode=AlphaMode::Cutout,
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
  category? : @item.Category = @item.Block,
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
  occlusion_cull? : Bool = true,
  same_block_cull? : Bool = false,
  luminance? : Int = 0,
  opacity? : Int = 15,
  alpha_mode? : AlphaMode = AlphaMode::Opaque,
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
      occlusion_cull~,
      same_block_cull~,
      luminance~,
      opacity~,
      alpha_mode~,
      shape~,
      material~,
      category~,
      faces,
    ),
    Block::create(
      id=alloc_id(),
      "classic." + name,
      state~,
      occlusion_cull~,
      same_block_cull~,
      luminance~,
      opacity~,
      alpha_mode~,
      shape~,
      material~,
      category~,
      faces.map(s => "classic/" + s),
    ),
  ]
}

///|
/// The long id of the air block should be an invariant
pub const AIR_LONG_ID : UInt = 0 // block_air.long_id()

///|
pub fn Block::is_air(block : Block) -> Bool {
  block.id == AIR_LONG_ID
}
