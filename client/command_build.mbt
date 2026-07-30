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
fn GameRuntime::build_deltas(
  self : GameRuntime,
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
        @block.lookup_by_internal_id(id).map(b => b.name).unwrap_or("air"),
      ),
    )
  }
  match build_type {
    Oak =>
      @feature.place_oak_tree_genus(
        set_block,
        wx,
        wy,
        wz,
        seed=self.world.seed(),
      )
    FallenOak =>
      @feature.place_fallen_oak_tree(
        set_block,
        wx,
        wy,
        wz,
        seed=self.world.seed(),
      )
    Cactus =>
      @feature.place_cactus(set_block, wx, wy, wz, seed=self.world.seed())
    NetherSpire => @structure.place_nether_spire(set_block, wx, wy, wz)
  }
  deltas
}
