///|
pub enum Shape {
  Air
  Cube
  GrassPath
  Liquid
  Cactus
  Torch
  RedstoneTorch
  RedstoneTorchClassic
}

///|
pub(all) enum RaycastMode {
  Skip
  Bounds
  LiquidBounds
}

///|
pub type PlacementState = (UInt, Array[Int], Array[Int], Array[Double]) -> UInt

///|
/// All behavior a block family contributes outside of its registry metadata.
/// Keep a new family's render, collision, targeting, and placement rules here.
pub(all) struct BlockProfile {
  model : @shape.Model
  collision_boxes : (UInt) -> Array[@shape.Box]
  raycast_boxes : (UInt) -> Array[@shape.Box]
  outline_boxes : (UInt) -> Array[@shape.Box]
  selectable : Bool
  raycast_mode : RaycastMode
  placement_state : PlacementState
}

///|
fn full_cube_boxes(_state : UInt) -> Array[@shape.Box] {
  [@shape.Box::{ min: [0.0F, 0.0F, 0.0F], max: [1.0F, 1.0F, 1.0F] }]
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
) -> UInt {
  state
}

///|
fn torch_placement_state(
  _state : UInt,
  block : Array[Int],
  prev : Array[Int],
  _player_pos : Array[Double],
) -> UInt {
  @genus.Torch::torch_state_from_placement(block, prev)
}

///|
fn axis_placement_state(
  _state : UInt,
  block : Array[Int],
  prev : Array[Int],
  _player_pos : Array[Double],
) -> UInt {
  @genus.Log::log_state_from_placement(block, prev)
}

///|
fn horizontal_placement_state(
  state : UInt,
  _block : Array[Int],
  prev : Array[Int],
  player_pos : Array[Double],
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
    Shape::Liquid => liquid_profile
    Shape::Cactus => cactus_profile
    Shape::Torch => torch_profile(@genus.torch_model)
    Shape::RedstoneTorch => torch_profile(@genus.redstone_torch_model)
    Shape::RedstoneTorchClassic =>
      torch_profile(@genus.redstone_torch_classic_model)
    Shape::Cube => facing_profile(block)
  }
}

///|
fn Block::profile(block : Block) -> BlockProfile {
  profile_by_block(block)
}

///|
pub fn model_by_block(block : Block) -> @shape.Model {
  block.profile().model
}

///|
pub fn Block::collision_boxes(block : Block) -> Array[@shape.Box] {
  (block.profile().collision_boxes)(block.state)
}

///|
pub fn Block::is_selectable(block : Block) -> Bool {
  block.profile().selectable
}

///|
pub fn Block::outline_boxes(block : Block) -> Array[@shape.Box] {
  (block.profile().outline_boxes)(block.state)
}

///|
pub fn get_shape_desc(long_id : UInt) -> @shape.Source? {
  lookup_by_long_id(long_id).map(block => @shape.Source::{
    boxes: block.collision_boxes(),
    facing: -1,
  })
}

///|
pub fn get_outline_desc(long_id : UInt) -> @shape.Source? {
  lookup_by_long_id(long_id).map(block => @shape.Source::{
    boxes: block.outline_boxes(),
    facing: -1,
  })
}

///|
fn ray_intersects_box(
  origin : Array[Double],
  direction : Array[Double],
  wx : Int,
  wy : Int,
  wz : Int,
  box : @shape.Box,
) -> Bool {
  let min = [
    wx.to_double() + box.min[0].to_double(),
    wy.to_double() + box.min[1].to_double(),
    wz.to_double() + box.min[2].to_double(),
  ]
  let max = [
    wx.to_double() + box.max[0].to_double(),
    wy.to_double() + box.max[1].to_double(),
    wz.to_double() + box.max[2].to_double(),
  ]
  let mut has_range = false
  let mut tmin = 0.0
  let mut tmax = 0.0
  for i in 0..<3 {
    let origin_value = origin[i]
    let direction_value = direction[i]
    if direction_value.abs() < 0.00000001 {
      if origin_value < min[i] || origin_value > max[i] {
        return false
      }
    } else {
      let inverse = 1.0 / direction_value
      let t1 = (min[i] - origin_value) * inverse
      let t2 = (max[i] - origin_value) * inverse
      let near = if t1 < t2 { t1 } else { t2 }
      let far = if t1 > t2 { t1 } else { t2 }
      if !has_range {
        tmin = near
        tmax = far
        has_range = true
      } else {
        if near > tmin {
          tmin = near
        }
        if far < tmax {
          tmax = far
        }
        if tmin > tmax {
          return false
        }
      }
    }
  }
  !has_range || tmax >= 0.0
}

///|
/// Test whether a ray can target the block's profile-defined bounds.
pub fn raycast_intersects(
  long_id : UInt,
  origin : Array[Double],
  direction : Array[Double],
  wx : Int,
  wy : Int,
  wz : Int,
  include_liquid : Bool,
) -> Bool {
  guard origin.length() >= 3 && direction.length() >= 3 else { false }
  match lookup_by_long_id(long_id) {
    None => false
    Some(block) => {
      let profile = block.profile()
      let can_raycast = match profile.raycast_mode {
        RaycastMode::Skip => false
        RaycastMode::Bounds => true
        RaycastMode::LiquidBounds => include_liquid
      }
      if !can_raycast {
        false
      } else {
        for box in (profile.raycast_boxes)(block.state) {
          if ray_intersects_box(origin, direction, wx, wy, wz, box) {
            return true
          }
        }
        false
      }
    }
  }
}
