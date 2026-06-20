///|
pub fn use_item_on(
  name : String,
  category : String,
  block : Array[Int],
  prev : Array[Int],
  click : (Float, Float, Float),
) -> UseOnAction {
  // STATUS: COMPLETE - dispatches current block placement and item-on-block
  // actions. Inventory mutation/count handling is intentionally not modeled yet.
  match @shape.FaceName::from_adjacent_blocks(block, prev) {
    None => UseOnAction::None
    Some(face) =>
      match UseTarget::from_wire(name, category) {
        KnownItem(item) =>
          item.use_on(
            ItemStack::from_item(item),
            block[0],
            block[1],
            block[2],
            face,
            click,
          )
        KnownBlock(block_name) =>
          PlaceBlock(
            target_wx=block[0],
            target_wy=block[1],
            target_wz=block[2],
            place_wx=prev[0],
            place_wy=prev[1],
            place_wz=prev[2],
            name=block_name,
            require_air=true,
          )
        Empty | Unknown => UseOnAction::None
      }
  }
}
