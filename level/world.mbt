///|
pub struct World {
  seed : UInt64
  world_type : WorldType
  noise : @util.PerlinNoise
}

///|
const DETAIL_SCALE : Double = 22.0

///|
const MIN_TERRAIN_HEIGHT : Int = 0

///|
const MAX_TERRAIN_HEIGHT : Int = 127

///|
const SEA_LEVEL : Int = 8

///|
const PV_FREQ : Double = 0.015

///|
const PLAINS_MOUNTAIN_AMP : Double = 12.0

///|
const MOUNTAIN_MOUNTAIN_AMP : Double = 40.0

///|
const DESERT_MOUNTAIN_AMP : Double = 6.0

///|
const PLAINS_BASE_OFFSET : Double = 0.0

///|
const MOUNTAIN_BASE_OFFSET : Double = 12.0

///|
const DESERT_BASE_OFFSET : Double = -2.0

///|
const TERRAIN_3D_FREQ : Double = 0.02

///|
const TERRAIN_3D_AMP : Double = 2.0

///|
const CAVE_FREQ : Double = 0.045

///|
const CAVE_THRESHOLD : Double = 0.28

///|
const PLAINS_MAX_HEIGHT : Int = 15

///|
const DESERT_MAX_HEIGHT : Int = 15

///|
const MOUNTAIN_MAX_HEIGHT : Int = 120

///|
const DESERT_SAND_DEPTH_MIN : Int = 4

///|
const DESERT_SAND_DEPTH_MAX : Int = 6

///|
const DESERT_SAND_SCALE : Double = 30.0

///|
const DESERT_SANDSTONE_DEPTH : Int = 4

///|
fn fbm2d(
  noise : @util.PerlinNoise,
  x : Double,
  z : Double,
  octaves : Int,
  lacunarity : Double,
  gain : Double,
) -> Double {
  let mut freq = 1.0
  let mut amp = 1.0
  let mut sum = 0.0
  let mut norm = 0.0
  for _ in 0..<octaves {
    sum = sum + noise.gen2d(x * freq, z * freq) * amp
    norm = norm + amp
    freq = freq * lacunarity
    amp = amp * gain
  }
  if norm == 0.0 {
    0.0
  } else {
    sum / norm
  }
}

///|
fn biome_at(world : World, wx : Int, wz : Int) -> @biome.Biome {
  let x = wx.to_double()
  let z = wz.to_double()
  let noise = world.noise
  let temp = fbm2d(
    noise,
    x * @biome.BIOME_FREQ,
    z * @biome.BIOME_FREQ,
    2,
    2.0,
    0.5,
  )
  let humid = fbm2d(
    noise,
    (x + 1000.0) * @biome.BIOME_FREQ,
    (z - 1000.0) * @biome.BIOME_FREQ,
    2,
    2.0,
    0.5,
  )
  if temp > 0.25 && humid < -0.05 {
    @biome.Desert
  } else {
    let mountain_mask = fbm2d(
      noise,
      x * @biome.MOUNTAIN_MASK_FREQ,
      z * @biome.MOUNTAIN_MASK_FREQ,
      2,
      2.0,
      0.5,
    ).abs()
    if mountain_mask > 0.35 {
      @biome.Mountains
    } else {
      @biome.Plains
    }
  }
}

///|
fn plain_height(world : World, wx : Int, wz : Int) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let noise = world.noise
  let biome = biome_at(world, wx, wz)
  let continental = fbm2d(
    noise,
    x * @biome.CONTINENTAL_FREQ,
    z * @biome.CONTINENTAL_FREQ,
    4,
    2.0,
    0.5,
  )
  let base = SEA_LEVEL.to_double() + continental * 6.0
  let base_offset = match biome {
    @biome.Plains => PLAINS_BASE_OFFSET
    @biome.Mountains => MOUNTAIN_BASE_OFFSET
    @biome.Desert => DESERT_BASE_OFFSET
  }
  let height = base + base_offset
  let h = height.round().to_int()
  let min_h = 5
  let max_h = 15
  if h < min_h {
    min_h
  } else if h > max_h {
    max_h
  } else {
    h
  }
}

///|
fn surface_height(world : World, wx : Int, wz : Int) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let noise = world.noise
  let biome = biome_at(world, wx, wz)
  let erosion = fbm2d(
    noise,
    x * @biome.EROSION_FREQ,
    z * @biome.EROSION_FREQ,
    3,
    2.0,
    0.5,
  )
  let peaks = fbm2d(noise, x * PV_FREQ, z * PV_FREQ, 3, 2.0, 0.5).abs()
  let erosion_t = (erosion + 1.0) / 2.0
  let ridge = peaks * peaks
  let (mountain_amp, max_h) = match biome {
    @biome.Plains => (2.0, PLAINS_MAX_HEIGHT)
    @biome.Mountains => (MOUNTAIN_MOUNTAIN_AMP, MOUNTAIN_MAX_HEIGHT)
    @biome.Desert => (1.0, DESERT_MAX_HEIGHT)
  }
  let mountain = ridge * mountain_amp * (1.0 - erosion_t * 0.6)
  let height = plain_height(world, wx, wz).to_double() + mountain
  let h = height.round().to_int()
  if h < MIN_TERRAIN_HEIGHT {
    MIN_TERRAIN_HEIGHT
  } else if h > max_h {
    max_h
  } else {
    h
  }
}

///|
fn surface_dirt_depth(world : World, wx : Int, wz : Int) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let detail = world.noise.gen2d(x / DETAIL_SCALE, z / DETAIL_SCALE).abs()
  3 + (detail * 2.0).floor().to_int()
}

///|
fn desert_sand_depth(world : World, wx : Int, wz : Int) -> Int {
  let x = wx.to_double()
  let z = wz.to_double()
  let t = world.noise.gen2d(x / DESERT_SAND_SCALE, z / DESERT_SAND_SCALE).abs()
  DESERT_SAND_DEPTH_MIN +
  (t * (DESERT_SAND_DEPTH_MAX - DESERT_SAND_DEPTH_MIN).to_double())
  .floor()
  .to_int()
}

///|
fn density_at(world : World, wx : Int, wy : Int, wz : Int) -> Double {
  let x = wx.to_double()
  let y = wy.to_double()
  let z = wz.to_double()
  let surface = surface_height(world, wx, wz).to_double()
  let plain = plain_height(world, wx, wz).to_double()
  if y > surface {
    -1.0
  } else if y <= plain {
    let cave = world.noise
      .gen3d(x * CAVE_FREQ, y * CAVE_FREQ, z * CAVE_FREQ)
      .abs()
    if y < plain - 1.0 && cave < CAVE_THRESHOLD {
      -1.0
    } else {
      1.0
    }
  } else {
    let carve = world.noise
      .gen3d(x * TERRAIN_3D_FREQ, y * TERRAIN_3D_FREQ, z * TERRAIN_3D_FREQ)
      .abs() *
      TERRAIN_3D_AMP
    let mut density = surface - y
    if y > plain + 3.0 {
      density = density - carve
    }
    if density <= 0.0 { -1.0 } else { density }
  }
}

///|
pub fn World::new(
  seed? : UInt64 = @env.now(),
  world_type? : WorldType = WorldType::PreClassic,
) -> World {
  let noise = @util.PerlinNoise::new(seed~)
  World::{ seed, world_type, noise }
}

///|
pub fn World::generate_chunk(
  self : World,
  chunk_x : Int,
  chunk_y : Int,
  chunk_z : Int,
) -> Chunk {
  let chunk = Chunk::new(chunk_x, chunk_y, chunk_z)
  match self.world_type {
    WorldType::Flat => fill_flat(chunk)
    WorldType::PreClassic => fill_pre_classic(self, chunk)
  }
}

///|
fn fill_flat(chunk : Chunk) -> Chunk {
  let air_id = @block.pack_long_id(@block.block_air.id, @block.block_air.state)
  let stone_id = @block.pack_long_id(
    @block.block_stone.id,
    @block.block_stone.state,
  )
  let grass_id = @block.pack_long_id(
    @block.block_grass.id,
    @block.block_grass.state,
  )
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      for ry in 0..<CHUNK_Y_SIZE {
        let (_, wy, _) = chunk.block_rxyz_to_block_xyz(rx, ry, rz)
        if wy < 0 {
          chunk.set_tile(rx, ry, rz, stone_id)
        } else if wy == 0 {
          chunk.set_tile(rx, ry, rz, grass_id)
        } else {
          chunk.set_tile(rx, ry, rz, air_id)
        }
      }
    }
  }
  chunk
}

///|
fn fill_pre_classic(world : World, chunk : Chunk) -> Chunk {
  let air_id = @block.pack_long_id(@block.block_air.id, @block.block_air.state)
  let stone_id = @block.pack_long_id(
    @block.block_stone.id,
    @block.block_stone.state,
  )
  let grass_id = @block.pack_long_id(
    @block.block_grass.id,
    @block.block_grass.state,
  )
  let dirt_id = @block.pack_long_id(
    @block.block_dirt.id,
    @block.block_dirt.state,
  )
  let sand_id = @block.pack_long_id(
    @block.block_sand.id,
    @block.block_sand.state,
  )
  let sandstone_id = @block.pack_long_id(
    @block.block_sandstone.id,
    @block.block_sandstone.state,
  )
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      let (wx, _, wz) = chunk.block_rxyz_to_block_xyz(rx, 0, rz)
      let biome = biome_at(world, wx, wz)
      let dirt_depth = surface_dirt_depth(world, wx, wz)
      let sand_depth = desert_sand_depth(world, wx, wz)
      let surface = surface_height(world, wx, wz)
      for ry in 0..<CHUNK_Y_SIZE {
        let (_, wy, _) = chunk.block_rxyz_to_block_xyz(rx, ry, rz)
        let density = density_at(world, wx, wy, wz)
        if density <= 0.0 {
          chunk.set_tile(rx, ry, rz, air_id)
        } else if wy == surface {
          match biome {
            @biome.Desert => chunk.set_tile(rx, ry, rz, sand_id)
            _ => chunk.set_tile(rx, ry, rz, grass_id)
          }
        } else if biome is @biome.Desert && wy >= surface - sand_depth {
          chunk.set_tile(rx, ry, rz, sand_id)
        } else if biome is @biome.Desert &&
          wy >= surface - sand_depth - DESERT_SANDSTONE_DEPTH {
          chunk.set_tile(rx, ry, rz, sandstone_id)
        } else if wy >= surface - dirt_depth {
          chunk.set_tile(rx, ry, rz, dirt_id)
        } else {
          chunk.set_tile(rx, ry, rz, stone_id)
        }
      }
    }
  }
  chunk
}
