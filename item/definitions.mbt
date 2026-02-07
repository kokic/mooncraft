///|
pub let items : Array[Item] = [
  Item::create(
    "iron_shovel",
    "item/iron_shovel",
    archetype=ItemArchetype::Tool(kind=ToolKind::Shovel, tier=ToolTier::Iron),
  ),
  Item::create("bucket", "item/bucket"),
  Item::create("water_bucket", "item/water_bucket"),
  Item::create("lava_bucket", "item/lava_bucket"),
]
