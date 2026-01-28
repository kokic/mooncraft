///|
pub enum WorldType {
  Flat
  PreClassic
}

///|
pub fn WorldType::flat() -> WorldType {
  WorldType::Flat
}

pub fn WorldType::preclassic() -> WorldType {
  WorldType::PreClassic
}

///|
pub struct World {
  seed : UInt64
  world_type : WorldType
  noise : @util.PerlinNoise
}

///|
pub fn World::new(seed? : UInt64 = @env.now(), world_type? : WorldType = WorldType::PreClassic) -> World {
  let noise = @util.PerlinNoise::new(seed~)
  World::{ seed, world_type, noise }
}

///|
pub fn World::generate_chunk(self : World, chunk_x : Int, chunk_y : Int, chunk_z : Int) -> Chunk {
  let chunk = Chunk::new(chunk_x, chunk_y, chunk_z)
  match self.world_type {
    WorldType::Flat => fill_flat(chunk)
    WorldType::PreClassic => fill_pre_classic(self, chunk)
  }
}

///|
fn fill_flat(chunk : Chunk) -> Chunk {
  let air_id = pack_long_id(block_air.id, block_air.state)
  let stone_id = pack_long_id(block_stone.id, block_stone.state)
  let grass_id = pack_long_id(block_grass.id, block_grass.state)
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
  let air_id = pack_long_id(block_air.id, block_air.state)
  let stone_id = pack_long_id(block_stone.id, block_stone.state)
  let grass_id = pack_long_id(block_grass.id, block_grass.state)
  let dirt_id = pack_long_id(block_dirt.id, block_dirt.state)
  let noise = world.noise
  for rx in 0..<CHUNK_X_SIZE {
    for rz in 0..<CHUNK_Z_SIZE {
      let (wx, _, wz) = chunk.block_rxyz_to_block_xyz(rx, 0, rz)
      let dx = wx.to_double()
      let dz = wz.to_double()
      let n1 = noise.gen2d(dx / 200.0, dz / 200.0)
      let n2 = noise.gen2d(dx / 50.0, dz / 50.0) / 2.0
      let n3 = noise.gen2d(dx / 10.0, dz / 10.0) / 64.0
      let elevation = ((n1 + n2 + n3) / 2.0 * 128.0).floor().to_int()
      let elevation = if elevation < 0 { 0 } else { elevation }
      for ry in 0..<CHUNK_Y_SIZE {
        let (_, wy, _) = chunk.block_rxyz_to_block_xyz(rx, ry, rz)
        if wy > elevation {
          chunk.set_tile(rx, ry, rz, air_id)
        } else if wy == elevation {
          chunk.set_tile(rx, ry, rz, grass_id)
        } else if wy >= elevation - 3 {
          chunk.set_tile(rx, ry, rz, dirt_id)
        } else {
          chunk.set_tile(rx, ry, rz, stone_id)
        }
      }
    }
  }
  chunk
}
