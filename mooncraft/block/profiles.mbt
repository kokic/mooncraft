///|
fn full_cube_boxes(_state : UInt) -> Array[@shape.Box] {
  [@shape.Box::{ min: [0.0F, 0.0F, 0.0F], max: [1.0F, 1.0F, 1.0F], }]
}

///|
fn no_boxes(_state : UInt) -> Array[@shape.Box] {
  []
}

///|
fn default_placement_state(
  state : UInt,
  _block : Array[Int],
  _prev : Array[Int],
  _player_pos : Array[Double],
  _click : (Float, Float, Float),
) -> UInt {
  state
}

///|
fn torch_placement_state(
  _state : UInt,
  block : Array[Int],
  prev : Array[Int],
  _player_pos : Array[Double],
  _click : (Float, Float, Float),
) -> UInt {
  @genus.Torch::torch_state_from_placement(block, prev)
}

///|
fn axis_placement_state(
  _state : UInt,
  block : Array[Int],
  prev : Array[Int],
  _player_pos : Array[Double],
  _click : (Float, Float, Float),
) -> UInt {
  @genus.Log::log_state_from_placement(block, prev)
}

///|
fn horizontal_placement_state(
  state : UInt,
  _block : Array[Int],
  prev : Array[Int],
  player_pos : Array[Double],
  _click : (Float, Float, Float),
) -> UInt {
  if prev.length() >= 3 {
    @genus.HorizontalFacing::state_from_player(player_pos, prev[0], prev[2])
  } else {
    state
  }
}

///|
fn six_placement_state(
  _state : UInt,
  block : Array[Int],
  prev : Array[Int],
  _player_pos : Array[Double],
  _click : (Float, Float, Float),
) -> UInt {
  @genus.SixFacing::state_from_hit(block, prev)
}

///|
fn torch_boxes(state : UInt) -> Array[@shape.Box] {
  [@genus.Torch::shape_box_by_state(state)]
}

///|
fn grass_path_boxes(_state : UInt) -> Array[@shape.Box] {
  [
    @shape.Box::{
      min: [0.0F, 0.0F, 0.0F],
      max: [1.0F, @genus.GRASS_PATH_MAX_Y, 1.0F],
    },
  ]
}

///|
fn cactus_boxes(_state : UInt) -> Array[@shape.Box] {
  [
    @shape.Box::{
      min: [@genus.CACTUS_MIN, 0.0F, @genus.CACTUS_MIN],
      max: [@genus.CACTUS_MAX, 1.0F, @genus.CACTUS_MAX],
    },
  ]
}

///|
fn slab_boxes(state : UInt) -> Array[@shape.Box] {
  [@genus.Slab::box(state)]
}

///|
fn slab_placement_state(
  _state : UInt,
  block : Array[Int],
  prev : Array[Int],
  _player_pos : Array[Double],
  click : (Float, Float, Float),
) -> UInt {
  @genus.Slab::state_from_placement(block, prev, click)
}

///|
fn vertical_slab_boxes(state : UInt) -> Array[@shape.Box] {
  [@genus.VerticalSlab::box(state)]
}

///|
fn vertical_slab_placement_state(
  _state : UInt,
  block : Array[Int],
  prev : Array[Int],
  _player_pos : Array[Double],
  click : (Float, Float, Float),
) -> UInt {
  @genus.VerticalSlab::state_from_placement(block, prev, click)
}

///|
let air_profile : BlockProfile = {
  model: @genus.default_model,
  collision_boxes: no_boxes,
  raycast_boxes: no_boxes,
  outline_boxes: no_boxes,
  selectable: false,
  raycast_mode: RaycastMode::Skip,
  placement_state: default_placement_state,
}

///|
let cube_profile : BlockProfile = {
  model: @genus.default_model,
  collision_boxes: full_cube_boxes,
  raycast_boxes: full_cube_boxes,
  outline_boxes: full_cube_boxes,
  selectable: true,
  raycast_mode: RaycastMode::Bounds,
  placement_state: default_placement_state,
}

///|
let grass_path_profile : BlockProfile = {
  model: @genus.grass_path_model,
  collision_boxes: grass_path_boxes,
  raycast_boxes: grass_path_boxes,
  outline_boxes: grass_path_boxes,
  selectable: true,
  raycast_mode: RaycastMode::Bounds,
  placement_state: default_placement_state,
}

///|
let liquid_profile : BlockProfile = {
  model: @genus.liquid_model,
  collision_boxes: no_boxes,
  raycast_boxes: full_cube_boxes,
  outline_boxes: no_boxes,
  selectable: false,
  raycast_mode: RaycastMode::LiquidBounds,
  placement_state: default_placement_state,
}

///|
let cactus_profile : BlockProfile = {
  model: @genus.cactus_model,
  collision_boxes: cactus_boxes,
  raycast_boxes: cactus_boxes,
  outline_boxes: cactus_boxes,
  selectable: true,
  raycast_mode: RaycastMode::Bounds,
  placement_state: default_placement_state,
}

///|
let slab_profile : BlockProfile = {
  model: @genus.slab_model,
  collision_boxes: slab_boxes,
  raycast_boxes: slab_boxes,
  outline_boxes: slab_boxes,
  selectable: true,
  raycast_mode: RaycastMode::Bounds,
  placement_state: slab_placement_state,
}

///|
let vertical_slab_profile : BlockProfile = {
  model: @genus.vertical_slab_model,
  collision_boxes: vertical_slab_boxes,
  raycast_boxes: vertical_slab_boxes,
  outline_boxes: vertical_slab_boxes,
  selectable: true,
  raycast_mode: RaycastMode::Bounds,
  placement_state: vertical_slab_placement_state,
}

///|
fn torch_profile(model : @shape.Model) -> BlockProfile {
  {
    model,
    collision_boxes: torch_boxes,
    raycast_boxes: torch_boxes,
    outline_boxes: torch_boxes,
    selectable: true,
    raycast_mode: RaycastMode::Bounds,
    placement_state: torch_placement_state,
  }
}

///|
/// Boxes derived from the baked glTF model's per-primitive bounds so collision,
/// raycast, and outline match the actual geometry. Falls back to a full cube
/// while the model is still loading.
fn gltf_model_boxes(name : String, state : UInt) -> Array[@shape.Box] {
  match @gltf.block_gltf_model(name) {
    None => full_cube_boxes(state)
    Some(model) =>
      model.primitives.map(primitive => @shape.Box::{
        min: [primitive.min_x, primitive.min_y, primitive.min_z],
        max: [primitive.max_x, primitive.max_y, primitive.max_z],
      })
  }
}

///|
/// Block whose render geometry is a baked glTF model. Collision and raycast
/// boxes follow the model's own extents; only the render model differs from
/// the procedural shapes.
fn gltf_profile(name : String) -> BlockProfile {
  let boxes = state => gltf_model_boxes(name, state)
  {
    model: @genus.default_model,
    collision_boxes: boxes,
    raycast_boxes: boxes,
    outline_boxes: boxes,
    selectable: true,
    raycast_mode: RaycastMode::Bounds,
    placement_state: default_placement_state,
  }
}

///|
fn facing_profile(block : Block) -> BlockProfile {
  match block.facing {
    Facing::Axis =>
      {
        ..cube_profile,
        model: @genus.log_model,
        placement_state: axis_placement_state,
      }
    Facing::Horizontal =>
      {
        ..cube_profile,
        model: @genus.horizontal_facing_model,
        placement_state: horizontal_placement_state,
      }
    Facing::Six =>
      {
        ..cube_profile,
        model: @genus.six_facing_model,
        placement_state: six_placement_state,
      }
    Facing::None => cube_profile
  }
}

///|
fn profile_by_block(block : Block) -> BlockProfile {
  match block.shape {
    Shape::Air => air_profile
    Shape::GrassPath => grass_path_profile
    Shape::Slab => slab_profile
    Shape::VerticalSlab => vertical_slab_profile
    Shape::Liquid => liquid_profile
    Shape::Cactus => cactus_profile
    Shape::Torch => torch_profile(@genus.torch_model)
    Shape::RedstoneTorch => torch_profile(@genus.redstone_torch_model)
    Shape::RedstoneTorchClassic =>
      torch_profile(@genus.redstone_torch_classic_model)
    Shape::Cube => facing_profile(block)
    Shape::Gltf => gltf_profile(block.name)
  }
}
