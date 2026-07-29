///|
priv enum BuildType {
  Oak
  FallenOak
  Cactus
  NetherSpire
}

///|
fn parse_build_command(build_type : StringView) -> ClientCommand {
  match build_type {
    "oak" => Build(Oak)
    "fallen_oak" => Build(FallenOak)
    "cactus" => Build(Cactus)
    "nether_spire" => Build(NetherSpire)
    _ => Invalid("Build type must be oak, fallen_oak, cactus, or nether_spire")
  }
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
    let name = @block.lookup_by_id(id).map(b => b.name).unwrap_or("air")
    deltas.push(@level.BlockDelta::new(x, y, z, name))
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
