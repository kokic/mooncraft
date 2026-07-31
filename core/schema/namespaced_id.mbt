///|
/// Persistent string identifier for a namespaced block/item name.
pub type UniqueID = String

///|
/// Runtime numeric identifier for a namespaced block/item variant.
/// Encodes (block_id, state) into a compact UInt for chunk storage.
pub type InternalID = UInt

///|
/// Encode block id and state into a variant InternalID.
/// stride = 256 gives 24 bits for block id (16M+) and 8 bits for state (256).
/// The state range is more than sufficient for facing variants (max 6).
pub fn encode_variant(block_id : UInt, state : UInt) -> InternalID {
  block_id * 256 + state
}

///|
/// Extract the base block id from a variant InternalID.
pub fn decode_block_id(variant : InternalID) -> UInt {
  variant / 256
}

///|
/// A sequential numeric ID allocator.
/// Each allocator manages an independent counter for a category (blocks, items, etc.).
pub struct InternalIDCounter {
  mut counter : InternalID
}

///|
pub fn InternalIDCounter::new() -> InternalIDCounter {
  InternalIDCounter::{ counter: 0 }
}

///|
pub fn InternalIDCounter::allocate(self : InternalIDCounter) -> InternalID {
  let id = self.counter
  self.counter = self.counter + 1
  id
}

///|
/// The persistent string identifier of the air block should be an invariant
pub const AIR_NAME : UniqueID = "air"

///|
/// The identifier (InternalID) of the air block should be an invariant
pub const AIR_ID : InternalID = 0
