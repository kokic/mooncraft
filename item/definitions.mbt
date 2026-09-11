///|
// STATUS: INCOMPLETE - registry contains the playable/demo items only. Add
// species-specific behavior before promoting bucket and spawn-egg placeholders.
pub let items : Array[Item] = [
  Item::create("iron_shovel", "item/iron_shovel", profile=shovel_profile),
  Item::create("bucket", "item/bucket", profile=bucket_profile),
  Item::create("water_bucket", "item/water_bucket"),
  Item::create("lava_bucket", "item/lava_bucket"),
]
