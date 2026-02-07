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
  Block::create("pumpkin", ["pumpkin_top", "pumpkin_top", "pumpkin_side"]),
  ..create_facing_group(
    "carved_pumpkin",
    [
      "carved_pumpkin", "pumpkin_side", "pumpkin_top", "pumpkin_top", "pumpkin_side",
      "pumpkin_side",
    ],
    facing=Facing::Horizontal,
  ),
  ..create_facing_group(
    "piston_sticky",
    [
      "piston_top_sticky", "piston_bottom", "piston_side", "piston_side", "piston_side",
      "piston_side",
    ],
    facing=Facing::Six,
  ),

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
  .map(v => create_facing_group(
    "classic.\{v}_log",
    ["classic/\{v}_log_top", "classic/\{v}_log"],
    facing=Facing::Axis,
  ))
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
fn unique_name_by_facing(
  base : String,
  facing : Facing,
  state : UInt,
) -> String {
  match facing {
    Facing::Axis => @genus.Log::unique_name(base, state)
    Facing::Horizontal => @genus.HorizontalFacing::unique_name(base, state)
    Facing::Six => @genus.SixFacing::unique_name(base, state)
    Facing::None => base
  }
}

///|
fn create_facing(
  base : String,
  id : UInt,
  state : UInt,
  faces : FixedArray[String],
  facing : Facing,
  shape? : Shape = Shape::Cube,
  category? : @item.Category = @item.Block,
) -> Block {
  Block::create(
    unique_name_by_facing(base, facing, state),
    id~,
    state~,
    facing~,
    shape~,
    category~,
    faces,
  )
}

///|
fn create_facing_group(
  base : String,
  id? : UInt = alloc_id(),
  faces : FixedArray[String],
  facing? : Facing = Facing::None,
  shape? : Shape = Shape::Cube,
) -> Array[Block] {
  match facing {
    Facing::Axis =>
      [
        create_facing(base, id, 0, faces, facing, shape~),
        create_facing(base, id, 1, faces, facing, shape~, category=@item.None),
        create_facing(base, id, 2, faces, facing, shape~, category=@item.None),
      ]
    Facing::Horizontal =>
      [
        create_facing(base, id, 0, faces, facing, shape~),
        create_facing(base, id, 1, faces, facing, shape~, category=@item.None),
        create_facing(base, id, 2, faces, facing, shape~, category=@item.None),
        create_facing(base, id, 3, faces, facing, shape~, category=@item.None),
      ]
    Facing::Six =>
      [
        create_facing(base, id, 0, faces, facing, shape~),
        create_facing(base, id, 1, faces, facing, shape~, category=@item.None),
        create_facing(base, id, 2, faces, facing, shape~, category=@item.None),
        create_facing(base, id, 3, faces, facing, shape~, category=@item.None),
        create_facing(base, id, 4, faces, facing, shape~, category=@item.None),
        create_facing(base, id, 5, faces, facing, shape~, category=@item.None),
      ]
    Facing::None => [create_facing(base, id, 0, faces, facing, shape~)]
  }
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
  facing? : Facing = Facing::None,
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
      facing~,
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
      facing~,
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
