///|
/// Geometry and recoloring share exactly the same render-bucket selection.
priv struct RenderBuckets[T] {
  normal : T
  leaf : T
  water : T
  translucent : T
}

///|
fn[T] RenderBuckets::new(make : () -> T) -> RenderBuckets[T] {
  { normal: make(), leaf: make(), water: make(), translucent: make(), }
}

///|
fn[T] RenderBuckets::for_block(
  self : RenderBuckets[T],
  render_block : @block.RenderBlock,
) -> T {
  if render_block.block.render_pass is @block.RenderPass::Liquid {
    self.water
  } else if render_block.block.render_pass is @block.RenderPass::Tinted {
    self.leaf
  } else if render_block.block.render_pass is @block.RenderPass::Translucent {
    self.translucent
  } else {
    self.normal
  }
}

///|
fn MeshFaceArrays::new() -> MeshFaceArrays {
  { positions: [], uvs: [], layers: [], colors: [], normals: None, }
}

///|
fn MeshFaceArrays::into_mesh(self : MeshFaceArrays) -> MeshData {
  {
    positions: self.positions,
    uvs: self.uvs,
    layers: self.layers,
    colors: self.colors,
    normals: [],
    count: self.positions.length() / 3,
  }
}

///|
fn RenderBuckets::into_mesh_split(
  self : RenderBuckets[MeshFaceArrays],
) -> MeshSplit {
  {
    normal: self.normal.into_mesh(),
    leaf: self.leaf.into_mesh(),
    water: self.water.into_mesh(),
    translucent: self.translucent.into_mesh(),
  }
}
