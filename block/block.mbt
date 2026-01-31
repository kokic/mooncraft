///|
/// Per-face material names from authoring data.
/// These are symbolic texture keys that get resolved into atlas indices later.
pub struct MaterialNames {
  pos_x : String?
  neg_x : String?
  pos_y : String?
  neg_y : String?
  pos_z : String?
  neg_z : String?
}

///|
pub fn MaterialNames::new(
  pos_x? : String,
  neg_x? : String,
  pos_y? : String,
  neg_y? : String,
  pos_z? : String,
  neg_z? : String,
) -> MaterialNames {
  MaterialNames::{ pos_x, neg_x, pos_y, neg_y, pos_z, neg_z }
}

///|
pub fn MaterialNames::isotropic(all : String) -> MaterialNames {
  MaterialNames::new(
    pos_x=all,
    neg_x=all,
    pos_y=all,
    neg_y=all,
    pos_z=all,
    neg_z=all,
  )
}

///|
pub fn MaterialNames::axial(axial : String, side : String) -> MaterialNames {
  MaterialNames::new(
    pos_x=side,
    neg_x=side,
    pos_y=axial,
    neg_y=axial,
    pos_z=side,
    neg_z=side,
  )
}

///|
pub fn MaterialNames::top_bottom(
  top : String,
  bottom : String,
  side : String,
) -> MaterialNames {
  MaterialNames::new(
    pos_x=side,
    neg_x=side,
    pos_y=top,
    neg_y=bottom,
    pos_z=side,
    neg_z=side,
  )
}

///|
/// Block definition used by both simulation and rendering.
/// Rendering derives texture indices from `faces`.
pub struct Block {
  /// unique internal name
  name : String
  id : UInt
  state : UInt
  opacity : Int
  luminance : Int
  shape : Shape
  faces : MaterialNames
}

///|
pub fn Block::long_id(block : Block) -> UInt {
  pack_long_id(block.id, block.state)
}

///|
pub fn pack_long_id(id : UInt, state : UInt) -> UInt {
  let id = id & 0xffff
  let state = state & 0xffff
  (state << 16) | id
}

///|
pub fn unpack_long_id(long_id : UInt) -> (UInt, UInt) {
  (long_id & 0xffff, long_id >> 16)
}
