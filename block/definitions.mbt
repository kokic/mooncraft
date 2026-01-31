///|
fn make_block(
  name : String,
  id : UInt,
  state : UInt,
  opacity : Int,
  luminance : Int,
  shape : Shape,
  faces : MaterialNames,
) -> Block {
  Block::{ name, id, state, opacity, luminance, shape, faces }
}

///|
pub let block_air : Block = make_block(
  "tile.air",
  alloc_id(),
  0,
  0,
  0,
  Shape::Normal,
  MaterialNames::new(),
)

///|
pub let block_stone : Block = make_block(
  "tile.stone",
  alloc_id(),
  0,
  15,
  0,
  Shape::Normal,
  MaterialNames::isotropic("stone"),
)

///|
pub let block_grass : Block = make_block(
  "tile.grass",
  alloc_id(),
  0,
  15,
  0,
  Shape::Normal,
  MaterialNames::top_bottom("grass_carried", "dirt", "grass_side_carried"),
)

///|
pub let block_dirt : Block = make_block(
  "tile.dirt",
  alloc_id(),
  0,
  15,
  0,
  Shape::Normal,
  MaterialNames::isotropic("dirt"),
)

///|
pub let block_sand : Block = make_block(
  "tile.sand",
  alloc_id(),
  0,
  15,
  0,
  Shape::Normal,
  MaterialNames::isotropic("sand"),
)

///|
pub let block_sandstone : Block = make_block(
  "tile.sandstone",
  alloc_id(),
  0,
  15,
  0,
  Shape::Normal,
  MaterialNames::top_bottom(
    "sandstone_top", "sandstone_bottom", "sandstone_normal",
  ),
)

///|
pub let block_sandstone_carved : Block = make_block(
  "tile.sandstone_carved",
  alloc_id(),
  0,
  15,
  0,
  Shape::Normal,
  MaterialNames::top_bottom(
    "sandstone_top", "sandstone_bottom", "sandstone_carved",
  ),
)

///|
pub let block_sandstone_smooth : Block = make_block(
  "tile.sandstone_smooth",
  alloc_id(),
  0,
  15,
  0,
  Shape::Normal,
  MaterialNames::top_bottom(
    "sandstone_top", "sandstone_bottom", "sandstone_smooth",
  ),
)

///|
pub let block_bedrock : Block = make_block(
  "tile.bedrock",
  alloc_id(),
  0,
  15,
  0,
  Shape::Normal,
  MaterialNames::isotropic("bedrock"),
)

///|
fn create_torch(
  base : String,
  id : UInt,
  state : UInt,
  material : MaterialNames,
  shape : Shape,
) -> Block {
  make_block(
    @genus.Torch::unique_name(base, state),
    id,
    state,
    15,
    0,
    shape,
    material,
  )
}

///|
fn add_torch_group(
  base : String,
  id : UInt,
  material : MaterialNames,
  shape : Shape,
) -> Array[Block] {
  let groups = [
    create_torch(base, id, 0, material, shape),
    create_torch(base, id, 1, material, shape),
    create_torch(base, id, 2, material, shape),
    create_torch(base, id, 3, material, shape),
    create_torch(base, id, 4, material, shape),
  ]
  blocks.append(groups) // side effect
  groups
}

///|
pub let torch_blocks : Array[Block] = add_torch_group(
  "tile.torch",
  alloc_id(),
  MaterialNames::isotropic("torch"),
  Shape::Torch,
)

///|
pub let redstone_torch_blocks : Array[Block] = add_torch_group(
  "tile.redstone_torch",
  alloc_id(),
  MaterialNames::isotropic("redstone_torch"),
  Shape::RedstoneTorch,
)

///|
pub let redstone_torch_classic_blocks : Array[Block] = add_torch_group(
  "tile.redstone_torch_classic",
  alloc_id(),
  MaterialNames::isotropic("redstone_torch_classic"),
  Shape::RedstoneTorchClassic,
)

///|
pub let soul_torch_blocks : Array[Block] = add_torch_group(
  "tile.soul_torch",
  alloc_id(),
  MaterialNames::isotropic("soul_torch"),
  Shape::Torch,
)

///|
pub let copper_torch_blocks : Array[Block] = add_torch_group(
  "tile.copper_torch",
  alloc_id(),
  MaterialNames::isotropic("copper_torch"),
  Shape::Torch,
)

///|
pub let blocks : Array[Block] = [
  block_air, block_stone, block_grass, block_dirt, block_sand, block_sandstone, block_sandstone_carved,
  block_sandstone_smooth, block_bedrock,
]

///|
let blocks_by_name : Map[String, Block] = {
  let out : Map[String, Block] = Map::new()
  for block in blocks {
    if !out.contains(block.name) {
      out[block.name] = block
    }
  }
  out
}

///|
let blocks_by_long_id : Map[UInt, Block] = {
  let out : Map[UInt, Block] = Map::new()
  for block in blocks {
    out[block.long_id()] = block
  }
  out
}

///|
pub fn get_block_by_name(name : String) -> Block? {
  blocks_by_name.get(name)
}

///|
pub fn get_block_by_long_id(long_id : UInt) -> Block? {
  blocks_by_long_id.get(long_id)
}

///|
pub fn get_long_id_by_name(name : String) -> UInt {
  match get_block_by_name(name) {
    Some(block) => block.long_id()
    None => block_air.long_id()
  }
}

///|
pub fn get_air_long_id() -> UInt {
  block_air.long_id()
}
