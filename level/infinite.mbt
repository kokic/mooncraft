///|
/// Infinite bottom layer Y (bedrock).
pub const INFINITE_MIN_Y : Int = WORLD_MIN_Y

///|
const DESERT_LAKE_CELL : Int = 32

///|
const DESERT_LAKE_RADIUS_MIN : Int = 5

///|
const DESERT_LAKE_RADIUS_MAX : Int = 11

///|
const DESERT_LAKE_DEPTH_MIN : Int = 4

///|
const DESERT_LAKE_DEPTH_MAX : Int = 10

///|
struct InfiniteColumnSample {
  terrain : TerrainColumn
  dirt_depth : Int
  sand_depth : Int
  bedrock_depth : Int
  top_solid_wy : Int
  inland_min_wy : Int
  densities : Array[Double]
  fluids : Array[TerrainFluid]
}

///|
fn InfiniteColumnSample::density_at(
  self : InfiniteColumnSample,
  wy : Int,
) -> Double {
  self.densities[wy - WORLD_MIN_Y]
}

///|
fn InfiniteColumnSample::fluid_at(
  self : InfiniteColumnSample,
  wy : Int,
) -> TerrainFluid {
  self.fluids[wy - WORLD_MIN_Y]
}

///|
fn noise01(value : Double) -> Double {
  @util.clamp01((value + 1.0) * 0.5)
}

///|
fn lerp_int(min : Int, max : Int, t : Double) -> Int {
  min + ((max - min).to_double() * @util.clamp01(t)).round().to_int()
}

///|
fn clamp_depth(depth : Int) -> Int {
  if depth < 2 {
    2
  } else if depth > 15 {
    15
  } else {
    depth
  }
}

///|
fn bedrock_thickness(world : World, wx : Int, wz : Int) -> Int {
  let coordinate_seed = wx * 73428767 +
    wz * 912931 +
    world.seed.reinterpret_as_int()
  let value = noise01(@util.Noise::fast(coordinate_seed))
  1 + (value * 4.999).floor().to_int()
}

///|
fn desert_lake_fill_depth(
  world : World,
  wx : Int,
  wz : Int,
  top_solid_wy : Int,
) -> Int {
  guard top_solid_wy >= SEA_LEVEL - 12 && top_solid_wy <= SEA_LEVEL + 18 else {
    0
  }
  let cell_x = @util.floor_div(wx, DESERT_LAKE_CELL)
  let cell_z = @util.floor_div(wz, DESERT_LAKE_CELL)
  let local_x = wx - cell_x * DESERT_LAKE_CELL
  let local_z = wz - cell_z * DESERT_LAKE_CELL
  let cx = cell_x.to_double()
  let cz = cell_z.to_double()
  let chance = noise01(
    world.noise.gen2d((cx * 47.0 + 3.0) * 0.23, (cz * 37.0 - 5.0) * 0.23),
  )
  guard chance >= 0.58 else { 0 }
  let center_x = lerp_int(
    7,
    DESERT_LAKE_CELL - 7,
    noise01(
      world.noise.gen2d((cx * 31.0 + 9.0) * 0.25, (cz * 29.0 - 4.0) * 0.25),
    ),
  )
  let center_z = lerp_int(
    7,
    DESERT_LAKE_CELL - 7,
    noise01(
      world.noise.gen2d((cx * 11.0 - 7.0) * 0.25, (cz * 41.0 + 2.0) * 0.25),
    ),
  )
  let radius_x = lerp_int(
    DESERT_LAKE_RADIUS_MIN,
    DESERT_LAKE_RADIUS_MAX,
    noise01(
      world.noise.gen2d((cx * 13.0 + 8.0) * 0.21, (cz * 59.0 - 1.0) * 0.21),
    ),
  )
  let radius_z = lerp_int(
    DESERT_LAKE_RADIUS_MIN,
    DESERT_LAKE_RADIUS_MAX,
    noise01(
      world.noise.gen2d((cx * 61.0 - 8.0) * 0.21, (cz * 17.0 + 7.0) * 0.21),
    ),
  )
  let nx = (local_x - center_x).to_double() / radius_x.to_double()
  let nz = (local_z - center_z).to_double() / radius_z.to_double()
  let basin = 1.0 - (nx * nx + nz * nz)
  guard basin > 0.0 else { 0 }
  let base_depth = lerp_int(
    DESERT_LAKE_DEPTH_MIN,
    DESERT_LAKE_DEPTH_MAX,
    noise01(
      world.noise.gen2d((cx * 23.0 + 10.0) * 0.19, (cz * 67.0 - 3.0) * 0.19),
    ),
  )
  clamp_depth(2 + (base_depth.to_double() * basin).round().to_int())
}

///|
/// Prepare all terrain state shared by the vertical chunks at one XZ block
/// coordinate. This is the canonical noise/density cache for column generation.
fn prepare_infinite_column(
  world : World,
  wx : Int,
  wz : Int,
) -> InfiniteColumnSample {
  let terrain = terrain_column(world, wx, wz)
  let densities : Array[Double] = []
  for wy in WORLD_MIN_Y..<=WORLD_MAX_Y {
    densities.push(density_at_column(world, terrain, wy))
  }
  let mut top_solid_wy = WORLD_MIN_Y
  for wy = WORLD_MAX_Y; wy > WORLD_MIN_Y; wy = wy - 1 {
    if densities[wy - WORLD_MIN_Y] > 0.0 {
      top_solid_wy = wy
      break
    }
  }
  let inland_depth = match terrain.surface_biome {
    @biome.DesertLakes => desert_lake_fill_depth(world, wx, wz, top_solid_wy)
    _ => 0
  }
  let inland_min_wy = top_solid_wy - inland_depth + 1
  let fluids : Array[TerrainFluid] = []
  for wy in WORLD_MIN_Y..<=WORLD_MAX_Y {
    fluids.push(aquifer_fluid_at(world, terrain, wy, top_solid_wy))
  }
  {
    terrain,
    dirt_depth: surface_dirt_depth(world, wx, wz),
    sand_depth: desert_sand_depth(world, wx, wz),
    bedrock_depth: bedrock_thickness(world, wx, wz),
    top_solid_wy,
    inland_min_wy,
    densities,
    fluids,
  }
}

///|
fn fill_infinite_block(
  world : World,
  chunk : Chunk,
  rx : Int,
  ry : Int,
  rz : Int,
  column : InfiniteColumnSample,
  bedrock : UInt,
  stone : UInt,
  grass : UInt,
  snow : UInt,
  dirt : UInt,
  sand : UInt,
  sandstone : UInt,
  water : UInt,
  lava : UInt,
  coal_ore : UInt,
  iron_ore : UInt,
  gold_ore : UInt,
  redstone_ore : UInt,
  diamond_ore : UInt,
  lapis_ore : UInt,
  emerald_ore : UInt,
) -> Unit {
  let air = @block.AIR_LONG_ID
  let (wx, wy, wz) = chunk.block_rxyz_to_block_xyz(rx, ry, rz)
  let biome = column.terrain.surface_biome
  let density = column.density_at(wy)
  let use_inland_water = column.inland_min_wy <= wy && wy <= column.top_solid_wy
  if wy < INFINITE_MIN_Y {
    chunk.update_tile_map(rx, ry, rz, air)
  } else if wy < INFINITE_MIN_Y + column.bedrock_depth {
    chunk.update_tile_map(rx, ry, rz, bedrock)
  } else if use_inland_water {
    chunk.update_tile_map(rx, ry, rz, water)
  } else if density <= 0.0 {
    match column.fluid_at(wy) {
      Air => chunk.update_tile_map(rx, ry, rz, air)
      Water => chunk.update_tile_map(rx, ry, rz, water)
      Lava => chunk.update_tile_map(rx, ry, rz, lava)
    }
  } else if wy == column.top_solid_wy {
    match biome {
      @biome.Ocean
      | @biome.DeepOcean
      | @biome.Desert
      | @biome.DesertLakes
      | @biome.Beach => chunk.update_tile_map(rx, ry, rz, sand)
      @biome.Mountains =>
        if wy >= SEA_LEVEL + 23 {
          chunk.update_tile_map(rx, ry, rz, snow)
        } else {
          chunk.update_tile_map(rx, ry, rz, grass)
        }
      @biome.WindsweptHills =>
        if wy >= SEA_LEVEL + 15 {
          chunk.update_tile_map(rx, ry, rz, snow)
        } else {
          chunk.update_tile_map(rx, ry, rz, grass)
        }
      _ => chunk.update_tile_map(rx, ry, rz, grass)
    }
  } else if (
      biome is @biome.Desert ||
      biome is @biome.DesertLakes ||
      biome is @biome.Beach ||
      biome is @biome.Ocean ||
      biome is @biome.DeepOcean
    ) &&
    wy >= column.top_solid_wy - column.sand_depth {
    chunk.update_tile_map(rx, ry, rz, sand)
  } else if (biome is @biome.Desert || biome is @biome.DesertLakes) &&
    wy >= column.top_solid_wy - column.sand_depth - DESERT_SANDSTONE_DEPTH {
    chunk.update_tile_map(rx, ry, rz, sandstone)
  } else if wy >= column.top_solid_wy - column.dirt_depth {
    chunk.update_tile_map(rx, ry, rz, dirt)
  } else {
    chunk.update_tile_map(
      rx,
      ry,
      rz,
      @feature.pick_stone_ore(
        world.noise,
        wx,
        wy,
        wz,
        biome is @biome.Mountains || biome is @biome.WindsweptHills,
        stone,
        coal_ore,
        iron_ore,
        gold_ore,
        redstone_ore,
        diamond_ore,
        lapis_ore,
        emerald_ore,
      ),
    )
  }
}

///|
/// Infinite terrain generation (biomes, soil, caves).
fn fill_infinite(world : World, chunk : Chunk) -> Chunk {
  let air = @block.AIR_LONG_ID
  let bedrock = @block.lookup_by_name("bedrock").unwrap().id
  let stone = @block.lookup_by_name("stone").unwrap().id
  let grass = @block.lookup_by_name("grass").unwrap().id
  let snow = @block.lookup_by_name("classic.snow").unwrap().id
  let dirt = @block.lookup_by_name("dirt").unwrap().id
  let sand = @block.lookup_by_name("sand").unwrap().id
  let sandstone = @block.lookup_by_name("sandstone").unwrap().id
  let water = @block.lookup_by_name("water").unwrap().id
  let lava = @block.lookup_by_name("lava").unwrap().id
  let coal_ore = @block.lookup_by_name("classic.coal_ore").unwrap().id
  let iron_ore = @block.lookup_by_name("classic.iron_ore").unwrap().id
  let gold_ore = @block.lookup_by_name("classic.gold_ore").unwrap().id
  let redstone_ore = @block.lookup_by_name("classic.redstone_ore").unwrap().id
  let diamond_ore = @block.lookup_by_name("classic.diamond_ore").unwrap().id
  let lapis_ore = @block.lookup_by_name("classic.lapis_ore").unwrap().id
  let emerald_ore = @block.lookup_by_name("classic.emerald_ore").unwrap().id
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      let (wx, _, wz) = chunk.block_rxyz_to_block_xyz(rx, 0, rz)
      let column = prepare_infinite_column(world, wx, wz)
      for ry in 0..<CHUNK_Y_SIZE {
        fill_infinite_block(
          world, chunk, rx, ry, rz, column, bedrock, stone, grass, snow, dirt, sand,
          sandstone, water, lava, coal_ore, iron_ore, gold_ore, redstone_ore, diamond_ore,
          lapis_ore, emerald_ore,
        )
      }
    }
  }
  place_biome_trees_in_chunk(world, chunk)
  chunk
}

///|
/// Generate a complete vertical infinite-terrain column. Each XZ sample is
/// prepared once, then consumed by every chunk at that position.
fn generate_infinite_chunk_column(
  world : World,
  chunk_x : Int,
  chunk_z : Int,
) -> Array[Chunk] {
  let chunks : Array[Chunk] = []
  let chunk_min_y = @util.floor_div(world.min_y(), CHUNK_Y_SIZE)
  let chunk_max_y = @util.floor_div(world.max_y(), CHUNK_Y_SIZE)
  for chunk_y in chunk_min_y..<=chunk_max_y {
    chunks.push(Chunk::new(chunk_x, chunk_y, chunk_z))
  }
  let columns : Array[InfiniteColumnSample] = []
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      columns.push(
        prepare_infinite_column(
          world,
          chunk_x * CHUNK_X_SIZE + rx,
          chunk_z * CHUNK_Z_SIZE + rz,
        ),
      )
    }
  }
  let bedrock = @block.lookup_by_name("bedrock").unwrap().id
  let stone = @block.lookup_by_name("stone").unwrap().id
  let grass = @block.lookup_by_name("grass").unwrap().id
  let snow = @block.lookup_by_name("classic.snow").unwrap().id
  let dirt = @block.lookup_by_name("dirt").unwrap().id
  let sand = @block.lookup_by_name("sand").unwrap().id
  let sandstone = @block.lookup_by_name("sandstone").unwrap().id
  let water = @block.lookup_by_name("water").unwrap().id
  let lava = @block.lookup_by_name("lava").unwrap().id
  let coal_ore = @block.lookup_by_name("classic.coal_ore").unwrap().id
  let iron_ore = @block.lookup_by_name("classic.iron_ore").unwrap().id
  let gold_ore = @block.lookup_by_name("classic.gold_ore").unwrap().id
  let redstone_ore = @block.lookup_by_name("classic.redstone_ore").unwrap().id
  let diamond_ore = @block.lookup_by_name("classic.diamond_ore").unwrap().id
  let lapis_ore = @block.lookup_by_name("classic.lapis_ore").unwrap().id
  let emerald_ore = @block.lookup_by_name("classic.emerald_ore").unwrap().id
  for chunk in chunks {
    for rx in 0..<CHUNK_X_SIZE {
      for rz in 0..<CHUNK_Z_SIZE {
        let column = columns[rx * CHUNK_Z_SIZE + rz]
        for ry in 0..<CHUNK_Y_SIZE {
          fill_infinite_block(
            world, chunk, rx, ry, rz, column, bedrock, stone, grass, snow, dirt,
            sand, sandstone, water, lava, coal_ore, iron_ore, gold_ore, redstone_ore,
            diamond_ore, lapis_ore, emerald_ore,
          )
        }
      }
    }
    place_biome_trees_in_chunk(world, chunk)
  }
  chunks
}
