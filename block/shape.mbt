///|
pub enum Shape {
  Air
  Cube
  Log
  GrassPath
  Liquid
  Cactus
  Torch
  RedstoneTorch
  RedstoneTorchClassic
}

///|
pub fn Shape::is_torch_genus(shape : Shape) -> Bool {
  match shape {
    Torch | RedstoneTorch | RedstoneTorchClassic => true
    _ => false
  }
}

///|
fn Shape::model(shape : Shape) -> @shape.Model {
  match shape {
    Shape::GrassPath => @genus.grass_path_model
    Shape::Liquid => @genus.liquid_model
    Shape::Cactus => @genus.cactus_model
    Shape::Log => @genus.log_model
    Shape::Torch => @genus.torch_model
    Shape::RedstoneTorch => @genus.redstone_torch_model
    Shape::RedstoneTorchClassic => @genus.redstone_torch_classic_model
    _ => @genus.default_model
  }
}

///|
fn shape_desc_by_block(block : Block) -> @shape.Source {
  match block.shape {
    shape if shape.is_torch_genus() => {
      let box = @genus.Torch::shape_box_by_state(block.state)
      @shape.Source::{
        boxes: [box],
        facing: block.state.reinterpret_as_int(),
      }
    }
    Shape::GrassPath =>
      @shape.Source::{
        boxes: [
          @shape.Box::{
            min: [0.0F, 0.0F, 0.0F],
            max: [1.0F, @genus.GRASS_PATH_MAX_Y, 1.0F],
          },
        ],
        facing: -1,
      }
    Shape::Liquid =>
      @shape.Source::{
        boxes: [
          @shape.Box::{
            min: [0.0F, 0.0F, 0.0F],
            max: [1.0F, @genus.LIQUID_MAX_Y, 1.0F],
          },
        ],
        facing: -1,
      }
    Shape::Cactus =>
      @shape.Source::{
        boxes: [
          @shape.Box::{
            min: [@genus.CACTUS_MIN, 0.0F, @genus.CACTUS_MIN],
            max: [@genus.CACTUS_MAX, 1.0F, @genus.CACTUS_MAX],
          },
        ],
        facing: -1,
      }
    _ =>
      @shape.Source::{
        boxes: [
          @shape.Box::{ min: [0.0F, 0.0F, 0.0F], max: [1.0F, 1.0F, 1.0F] },
        ],
        facing: -1,
      }
  }
}

///|
pub fn get_shape_desc(long_id : UInt) -> @shape.Source? {
  match lookup_by_long_id(long_id) {
    Some(block) => Some(shape_desc_by_block(block))
    None => None
  }
}
