///|
fn face_from_hit(
  block : Array[Int],
  prev : Array[Int],
) -> @shape.FaceName? {
  if block.length() < 3 || prev.length() < 3 {
    None
  } else {
    let dx = block[0] - prev[0]
    let dy = block[1] - prev[1]
    let dz = block[2] - prev[2]
    if dx == -1 {
      Some(@shape.FaceName::PosX)
    } else if dx == 1 {
      Some(@shape.FaceName::NegX)
    } else if dy == -1 {
      Some(@shape.FaceName::PosY)
    } else if dy == 1 {
      Some(@shape.FaceName::NegY)
    } else if dz == -1 {
      Some(@shape.FaceName::PosZ)
    } else if dz == 1 {
      Some(@shape.FaceName::NegZ)
    } else {
      None
    }
  }
}

///|
pub fn use_item_on_block(
  name : String,
  category : String,
  block : Array[Int],
  prev : Array[Int],
) -> UseOnAction {
  if block.length() < 3 || prev.length() < 3 {
    UseOnAction::None
  } else {
    match category {
      "item" =>
        match lookup_by_name(name) {
          None => UseOnAction::None
          Some(item) =>
            match face_from_hit(block, prev) {
              None => UseOnAction::None
              Some(face) =>
                item.use_on(
                  ItemStack::from_item(item),
                  block[0],
                  block[1],
                  block[2],
                  face,
                )
            }
        }
      "block" =>
        match face_from_hit(block, prev) {
          None => UseOnAction::None
          Some(_) =>
            UseOnAction::PlaceBlock(
              target_wx=block[0],
              target_wy=block[1],
              target_wz=block[2],
              place_wx=prev[0],
              place_wy=prev[1],
              place_wz=prev[2],
              name=name,
              require_air=true,
            )
        }
      _ => UseOnAction::None
    }
  }
}
