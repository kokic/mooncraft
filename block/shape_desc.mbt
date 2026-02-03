///|
pub struct ShapeBox {
  min : Array[Float]
  max : Array[Float]
}

///|
pub struct ShapeDesc {
  boxes : Array[ShapeBox]
  facing : Int
}

///|
fn torch_bounds_by_state(state : UInt) -> (Array[Float], Array[Float]) {
  let bounds = @genus.Torch::collect_bounds()
  let idx = match state.reinterpret_as_int() {
    1 => 2 // north
    2 => 4 // south
    3 => 6 // west
    4 => 8 // east
    _ => 0 // floor
  }
  (bounds[idx], bounds[idx + 1])
}

///|
fn shape_desc_by_block(block : Block) -> ShapeDesc {
  match block.shape {
    shape if shape.is_torch_genus() => {
      let (bmin, bmax) = torch_bounds_by_state(block.state)
      ShapeDesc::{
        boxes: [ShapeBox::{ min: bmin, max: bmax }],
        facing: block.state.reinterpret_as_int(),
      }
    }
    _ =>
      ShapeDesc::{
        boxes: [ShapeBox::{ min: [0.0F, 0.0F, 0.0F], max: [1.0F, 1.0F, 1.0F] }],
        facing: -1,
      }
  }
}

///|
pub fn get_shape_desc(long_id : UInt) -> ShapeDesc? {
  match lookup_by_long_id(long_id) {
    Some(block) => Some(shape_desc_by_block(block))
    None => None
  }
}
