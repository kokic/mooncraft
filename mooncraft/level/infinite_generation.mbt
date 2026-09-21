///|
priv enum InfiniteColumnGenerationStage {
  SampleColumns
  FillColumns
  PlaceTrees
  Complete
}

///|
/// Incremental generation state for one complete Infinite-world chunk column.
/// Completed chunks remain private until every terrain and feature step finishes.
pub struct InfiniteChunkColumnGeneration {
  column_key : String
  advance_impl : (Int) -> Bool
  completed_chunks_impl : () -> Array[Chunk]?
}

///|
priv struct InfiniteChunkColumnGenerationState {
  world : World
  chunk_x : Int
  chunk_z : Int
  chunks : Array[Chunk]
  columns : Array[InfiniteColumnSample]
  palette : InfiniteBlockPalette
  mut stage : InfiniteColumnGenerationStage
  mut next_index : Int
}

///|
pub fn World::begin_infinite_chunk_column_generation(
  world : World,
  chunk_x : Int,
  chunk_z : Int,
) -> InfiniteChunkColumnGeneration {
  let chunks : Array[Chunk] = []
  let chunk_min_y = @util.floor_div(world.min_y(), CHUNK_Y_SIZE)
  let chunk_max_y = @util.floor_div(world.max_y(), CHUNK_Y_SIZE)
  for chunk_y in chunk_min_y..<=chunk_max_y {
    chunks.push(Chunk::new(chunk_x, chunk_y, chunk_z))
  }
  let state = InfiniteChunkColumnGenerationState::{
    world,
    chunk_x,
    chunk_z,
    chunks,
    columns: [],
    palette: InfiniteBlockPalette::new(),
    stage: SampleColumns,
    next_index: 0,
  }
  {
    column_key: chunk_column_key_by_chunk_xz(chunk_x, chunk_z),
    advance_impl: budget => state.advance(budget),
    completed_chunks_impl: () => state.completed_chunks(),
  }
}

///|
pub fn InfiniteChunkColumnGeneration::column_key(
  self : InfiniteChunkColumnGeneration,
) -> String {
  self.column_key
}

///|
fn InfiniteChunkColumnGenerationState::sample_next_column(
  self : InfiniteChunkColumnGenerationState,
) -> Unit {
  let rx = self.next_index / CHUNK_Z_SIZE
  let rz = self.next_index % CHUNK_Z_SIZE
  self.columns.push(
    prepare_infinite_column(
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
fn InfiniteChunkColumnGenerationState::fill_next_column(
  self : InfiniteChunkColumnGenerationState,
) -> Unit {
  let rx = self.next_index / CHUNK_Z_SIZE
  let rz = self.next_index % CHUNK_Z_SIZE
  let column = self.columns[self.next_index]
  for chunk in self.chunks {
    for ry in 0..<CHUNK_Y_SIZE {
      fill_infinite_block(self.world, chunk, rx, ry, rz, column, self.palette)
    }
  }
  self.next_index += 1
  if self.next_index == CHUNK_X_SIZE * CHUNK_Z_SIZE {
    self.stage = PlaceTrees
    self.next_index = 0
  }
}

///|
fn InfiniteChunkColumnGenerationState::place_trees(
  self : InfiniteChunkColumnGenerationState,
) -> Unit {
  for chunk in self.chunks {
    place_biome_trees_in_generated_chunk(
      self.world,
      chunk,
      self.columns,
      self.palette.grass,
    )
  }
  self.stage = Complete
}

///|
/// Advance at most `work_budget` bounded XZ or feature work units.
/// Returns true only after the complete vertical column is ready to publish.
fn InfiniteChunkColumnGenerationState::advance(
  self : InfiniteChunkColumnGenerationState,
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
fn InfiniteChunkColumnGenerationState::completed_chunks(
  self : InfiniteChunkColumnGenerationState,
) -> Array[Chunk]? {
  if self.stage is Complete {
    Some(self.chunks)
  } else {
    None
  }
}

///|
pub fn InfiniteChunkColumnGeneration::advance(
  self : InfiniteChunkColumnGeneration,
  work_budget : Int,
) -> Bool {
  (self.advance_impl)(work_budget)
}

///|
pub fn InfiniteChunkColumnGeneration::completed_chunks(
  self : InfiniteChunkColumnGeneration,
) -> Array[Chunk]? {
  (self.completed_chunks_impl)()
}

///|
/// Generate a complete vertical infinite-terrain column. Each XZ sample is
/// prepared once, then consumed by every chunk at that position.
fn generate_infinite_chunk_column(
  world : World,
  chunk_x : Int,
  chunk_z : Int,
) -> Array[Chunk] {
  let generation = world.begin_infinite_chunk_column_generation(
    chunk_x, chunk_z,
  )
  while !generation.advance(64) {

  }
  match generation.completed_chunks() {
    Some(chunks) => chunks
    None => abort("completed infinite column generation has no chunks")
  }
}
