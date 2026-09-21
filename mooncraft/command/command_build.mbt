///|
pub enum BuildType {
  Oak
  FallenOak
  Cactus
  NetherSpire
}

///|
pub fn BuildType::from_name(name : String) -> BuildType? {
  Some(
    match name {
      "oak" => Oak
      "fallen_oak" => FallenOak
      "cactus" => Cactus
      "nether_spire" => NetherSpire
      _ => return None
    },
  )
}

///|
fn build_deltas(
  seed : UInt,
  build_type : BuildType,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Array[@level.BlockDelta] {
  let deltas : Array[@level.BlockDelta] = []
  let set_block = (x : Int, y : Int, z : Int, id : UInt) => {
    deltas.push(
      @level.BlockDelta::new(
        x,
        y,
        z,
        @block.lookup_by_internal_id(id).map_or(@schema.AIR_NAME, b => b.name),
      ),
    )
  }
  match build_type {
    Oak => @feature.place_oak_tree_genus(set_block, wx, wy, wz, seed~)
    FallenOak => @feature.place_fallen_oak_tree(set_block, wx, wy, wz, seed~)
    Cactus => @feature.place_cactus(set_block, wx, wy, wz, seed~)
    NetherSpire => @structure.place_nether_spire(set_block, wx, wy, wz)
  }
  deltas
}
