///|
priv enum ColumnGenerationStage {
  SampleColumns
  FillColumns
  PlaceTrees
  Complete
}

///|
/// Incremental generation state for one complete world chunk column. Completed
/// chunks remain private until every terrain and feature step finishes.
pub struct ChunkColumnGeneration {
  column_key : String
  advance_impl : (Int) -> Bool
  completed_chunks_impl : () -> Array[Chunk]?
}

///|
priv struct ChunkColumnGenerationState {
  world : World
  chunk_x : Int
  chunk_z : Int
  chunks : Array[Chunk]
  columns : Array[TerrainColumnSample]
  palette : TerrainBlockPalette
  mut stage : ColumnGenerationStage
  mut next_index : Int
}

///|
pub fn World::begin_chunk_column_generation(
  world : World,
  chunk_x : Int,
  chunk_z : Int,
) -> ChunkColumnGeneration {
  let chunks : Array[Chunk] = []
  let chunk_min_y = @util.floor_div(world.min_y(), CHUNK_Y_SIZE)
  let chunk_max_y = @util.floor_div(world.max_y(), CHUNK_Y_SIZE)
  for chunk_y in chunk_min_y..<=chunk_max_y {
    chunks.push(Chunk::new(chunk_x, chunk_y, chunk_z))
  }
  // Finite worlds are bounded: columns outside the region stay generated air.
  let generates_terrain = world.is_column_generated(chunk_x, chunk_z)
  let state = ChunkColumnGenerationState::{
    world,
    chunk_x,
    chunk_z,
    chunks,
    columns: [],
    palette: TerrainBlockPalette::new(),
    stage: if generates_terrain { SampleColumns } else { Complete },
    next_index: 0,
  }
  {
    column_key: chunk_column_key_by_chunk_xz(chunk_x, chunk_z),
    advance_impl: budget => state.advance(budget),
    completed_chunks_impl: () => state.completed_chunks(),
  }
}

///|
pub fn ChunkColumnGeneration::column_key(
  self : ChunkColumnGeneration,
) -> String {
  self.column_key
}

///|
fn ChunkColumnGenerationState::sample_next_column(
  self : ChunkColumnGenerationState,
) -> Unit {
  let rx = self.next_index / CHUNK_Z_SIZE
  let rz = self.next_index % CHUNK_Z_SIZE
  self.columns.push(
    prepare_terrain_column(
      self.world,
      self.chunk_x * CHUNK_X_SIZE + rx,
      self.chunk_z * CHUNK_Z_SIZE + rz,
    ),
  )
  self.next_index += 1
  if self.next_index == CHUNK_X_SIZE * CHUNK_Z_SIZE {
    self.stage = FillColumns
    self.next_index = 0
  }
}

///|
fn ChunkColumnGenerationState::fill_next_column(
  self : ChunkColumnGenerationState,
) -> Unit {
  let rx = self.next_index / CHUNK_Z_SIZE
  let rz = self.next_index % CHUNK_Z_SIZE
  let column = self.columns[self.next_index]
  for chunk in self.chunks {
    for ry in 0..<CHUNK_Y_SIZE {
      fill_terrain_block(self.world, chunk, rx, ry, rz, column, self.palette)
    }
  }
  self.next_index += 1
  if self.next_index == CHUNK_X_SIZE * CHUNK_Z_SIZE {
    self.stage = PlaceTrees
    self.next_index = 0
  }
}

///|
fn ChunkColumnGenerationState::place_trees(
  self : ChunkColumnGenerationState,
) -> Unit {
  for chunk in self.chunks {
    place_biome_trees_in_generated_chunk(
      self.world,
      chunk,
      self.columns,
      self.palette.grass,
    )
  }
  place_terrain_structures(self.world, self.chunks)
  self.stage = Complete
}

///|
/// Advance at most `work_budget` bounded XZ or feature work units.
/// Returns true only after the complete vertical column is ready to publish.
fn ChunkColumnGenerationState::advance(
  self : ChunkColumnGenerationState,
  work_budget : Int,
) -> Bool {
  guard work_budget > 0 else { return self.stage is Complete }
  for _ in 0..<work_budget {
    match self.stage {
      SampleColumns => self.sample_next_column()
      FillColumns => self.fill_next_column()
      PlaceTrees => self.place_trees()
      Complete => return true
    }
  }
  self.stage is Complete
}

///|
fn ChunkColumnGenerationState::completed_chunks(
  self : ChunkColumnGenerationState,
) -> Array[Chunk]? {
  if self.stage is Complete {
    Some(self.chunks)
  } else {
    None
  }
}

///|
pub fn ChunkColumnGeneration::advance(
  self : ChunkColumnGeneration,
  work_budget : Int,
) -> Bool {
  (self.advance_impl)(work_budget)
}

///|
pub fn ChunkColumnGeneration::completed_chunks(
  self : ChunkColumnGeneration,
) -> Array[Chunk]? {
  (self.completed_chunks_impl)()
}

///|
/// Generate a complete vertical terrain column. Each XZ sample is prepared once,
/// then consumed by every chunk at that position.
fn generate_terrain_chunk_column(
  world : World,
  chunk_x : Int,
  chunk_z : Int,
) -> Array[Chunk] {
  let generation = world.begin_chunk_column_generation(chunk_x, chunk_z)
  while !generation.advance(64) {

  }
  match generation.completed_chunks() {
    Some(chunks) => chunks
    None => abort("completed chunk column generation has no chunks")
  }
}
