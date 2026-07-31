///|
// STATUS: INCOMPLETE - this is not a full Minecraft registry; many categories
// and block behaviors are data-only or absent.
pub let blocks : Array[Block] = [
  // Basic (id: 0)
  Block::create(
    @schema.AIR_NAME,
    [],
    opacity=0,
    alpha_mode=AlphaMode::Cutout,
    occlusion_cull=false,
    shape=Shape::Air,
    category=@item.None,
  ),
  Block::create("stone", ["stone"]),
  // Modern overworld underground material. The current asset set reuses the
  // stone texture until a dedicated deepslate texture is added.
  Block::create("deepslate", ["stone"]),
  Block::create("bedrock", ["bedrock"]),
  Block::create("obsidian", ["obsidian"]),
  Block::create("classic.obsidian", ["classic/obsidian"]),
  Block::create("crying_obsidian", ["crying_obsidian"]),
  Block::create("glowing_obsidian", ["pre-classic/glowing_obsidian"]),

  // Terrain
  Block::create("grass_snow", ["snow", "dirt", "grass_side_snowed"]),
  Block::create("classic.grass_snow", [
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
    material=Material::Water,
    opacity=1,
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
  .map(v => {
    create_facing_group(
      "classic.\{v}_log",
      ["classic/\{v}_log_top", "classic/\{v}_log"],
      facing=Facing::Axis,
    )
  })
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
  Block::create("oak_planks", ["classic/oak_planks"]),

  // Wool
  ..[
    "black", "blue", "brown", "cyan", "gray", "green", "light_blue", "light_gray",
    "lime", "magenta", "orange", "pink", "purple", "red", "white", "yellow",
  ].map(v => Block::create("\{v}_wool", ["\{v}_wool"])),

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
fn create_torch(
  base : String,
  state : UInt,
  faces : FixedArray[String],
  shape : Shape,
  id : BlockId,
  luminance? : Int = 0,
  category? : @item.Category = @item.Block,
) -> Block {
  Block::unsafe_create_with_specified_id(
    @genus.Torch::unique_name(base, state),
    occlusion_cull=false,
    alpha_mode=AlphaMode::Cutout,
    luminance~,
    state~,
    shape~,
    category~,
    faces,
    id,
  )
}

///|
fn create_torch_group(
  base : String,
  faces : FixedArray[String],
  shape : Shape,
  luminance? : Int = 0,
) -> Array[Block] {
  let id = alloc_block_id()
  [
    create_torch(base, 0, faces, shape, id, luminance~),
    create_torch(base, 1, faces, shape, id, luminance~, category=@item.None),
    create_torch(base, 2, faces, shape, id, luminance~, category=@item.None),
    create_torch(base, 3, faces, shape, id, luminance~, category=@item.None),
    create_torch(base, 4, faces, shape, id, luminance~, category=@item.None),
  ]
}

///|
pub fn variant_name(base : String, facing : Facing, state : UInt) -> String {
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
  state : UInt,
  faces : FixedArray[String],
  facing : Facing,
  id : BlockId,
  shape? : Shape = Shape::Cube,
  category? : @item.Category = @item.Block,
) -> Block {
  Block::unsafe_create_with_specified_id(
    variant_name(base, facing, state),
    state~,
    facing~,
    shape~,
    category~,
    faces,
    id,
  )
}

///|
fn create_facing_group(
  base : String,
  faces : FixedArray[String],
  facing? : Facing = Facing::None,
  shape? : Shape = Shape::Cube,
) -> Array[Block] {
  let id = alloc_block_id()
  match facing {
    Facing::Axis =>
      [
        create_facing(base, 0, faces, facing, id, shape~),
        create_facing(base, 1, faces, facing, id, shape~, category=@item.None),
        create_facing(base, 2, faces, facing, id, shape~, category=@item.None),
      ]
    Facing::Horizontal =>
      [
        create_facing(base, 0, faces, facing, id, shape~),
        create_facing(base, 1, faces, facing, id, shape~, category=@item.None),
        create_facing(base, 2, faces, facing, id, shape~, category=@item.None),
        create_facing(base, 3, faces, facing, id, shape~, category=@item.None),
      ]
    Facing::Six =>
      [
        create_facing(base, 0, faces, facing, id, shape~),
        create_facing(base, 1, faces, facing, id, shape~, category=@item.None),
        create_facing(base, 2, faces, facing, id, shape~, category=@item.None),
        create_facing(base, 3, faces, facing, id, shape~, category=@item.None),
        create_facing(base, 4, faces, facing, id, shape~, category=@item.None),
        create_facing(base, 5, faces, facing, id, shape~, category=@item.None),
      ]
    Facing::None => [create_facing(base, 0, faces, facing, id, shape~)]
  }
}

///|
fn Block::create_with_classic(
  name : @schema.UniqueID,
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
pub fn Block::is_air(block : Block) -> Bool {
  block.id == 0
}

///|
pub fn Block::is_water(block : Block) -> Bool {
  block.material.is_water()
}
