///|
pub enum RenderType {
  Normal
}

///|
pub struct Block {
  name : String
  id : UInt
  state : UInt
  opacity : Int
  render_type : RenderType
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

///|
pub let block_air : Block = Block::{
  name: "air",
  id: 0,
  state: 0,
  opacity: 0,
  render_type: RenderType::Normal,
}

///|
pub let block_stone : Block = Block::{
  name: "stone",
  id: 1,
  state: 0,
  opacity: 15,
  render_type: RenderType::Normal,
}

///|
pub let block_grass : Block = Block::{
  name: "grass",
  id: 2,
  state: 0,
  opacity: 15,
  render_type: RenderType::Normal,
}

///|
pub let block_dirt : Block = Block::{
  name: "dirt",
  id: 3,
  state: 0,
  opacity: 15,
  render_type: RenderType::Normal,
}

///|
pub let block_sand : Block = Block::{
  name: "sand",
  id: 4,
  state: 0,
  opacity: 15,
  render_type: RenderType::Normal,
}

///|
pub let block_sandstone : Block = Block::{
  name: "sandstone",
  id: 5,
  state: 0,
  opacity: 15,
  render_type: RenderType::Normal,
}

///|
pub fn get_block_by_name(name : String) -> Block? {
  match name {
    "air" => Some(block_air)
    "stone" => Some(block_stone)
    "grass" => Some(block_grass)
    "dirt" => Some(block_dirt)
    "sand" => Some(block_sand)
    "sandstone" => Some(block_sandstone)
    _ => None
  }
}

///|
pub fn get_block_by_long_id(long_id : UInt) -> Block? {
  let (id, state) = unpack_long_id(long_id)
  match (id, state) {
    (0, _) => Some(block_air)
    (1, 0) => Some(block_stone)
    (2, 0) => Some(block_grass)
    (3, 0) => Some(block_dirt)
    (4, 0) => Some(block_sand)
    (5, 0) => Some(block_sandstone)
    _ => None
  }
}
