///|
pub let hotbar_blocks : Array[@block.Block] = [
  @block.block_stone,
  @block.block_grass,
  @block.block_dirt,
  // @block.block_sand,
  @block.block_sandstone_carved,
  @block.torch_blocks[0],
  @block.redstone_torch_blocks[0],
  @block.redstone_torch_classic_blocks[0],
  @block.soul_torch_blocks[0],
  @block.copper_torch_blocks[0],
]

///|
pub fn collect_hotbar_defs() -> Array[Array[String]] {
  let out : Array[Array[String]] = []
  let to_name = fn(value : String?) -> String {
    match value {
      Some(name) => name
      None => ""
    }
  }
  let shape_tag = fn(shape : @block.Shape) -> String {
    match shape {
      @block.Shape::Torch
      | @block.Shape::RedstoneTorch
      | @block.Shape::RedstoneTorchClassic => "torch"
      _ => "normal"
    }
  }
  let pick_side = fn(faces : @block.MaterialNames) -> String {
    match faces {
      { pos_x: Some(name), .. } => name
      { pos_z: Some(name), .. } => name
      { neg_x: Some(name), .. } => name
      { neg_z: Some(name), .. } => name
      { pos_y: Some(name), .. } => name
      { neg_y: Some(name), .. } => name
      _ => ""
    }
  }
  for block in hotbar_blocks {
    if block.shape is @block.Shape::Torch ||
      block.shape is @block.Shape::RedstoneTorch ||
      block.shape is @block.Shape::RedstoneTorchClassic {
      let tex = to_name(block.faces.pos_x)
      out.push([block.name, "torch", "flat", "", "", "", tex])
    } else {
      let faces = block.faces
      out.push([
        block.name,
        shape_tag(block.shape),
        "block",
        to_name(faces.pos_y),
        pick_side(faces),
        to_name(faces.neg_y),
        "",
      ])
    }
  }
  out
}
