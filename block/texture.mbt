///|
/// Per-face material names from authoring data.
/// These are symbolic texture keys that get resolved into atlas indices later.
pub struct TextureNames {
  pos_x : String?
  neg_x : String?
  pos_y : String?
  neg_y : String?
  pos_z : String?
  neg_z : String?
}

///|
pub fn TextureNames::new(
  pos_x? : String,
  neg_x? : String,
  pos_y? : String,
  neg_y? : String,
  pos_z? : String,
  neg_z? : String,
) -> TextureNames {
  TextureNames::{ pos_x, neg_x, pos_y, neg_y, pos_z, neg_z }
}

///|
pub fn TextureNames::isotropic(all : String) -> TextureNames {
  TextureNames::new(
    pos_x=all,
    neg_x=all,
    pos_y=all,
    neg_y=all,
    pos_z=all,
    neg_z=all,
  )
}

///|
pub fn TextureNames::axial(axial : String, side : String) -> TextureNames {
  TextureNames::new(
    pos_x=side,
    neg_x=side,
    pos_y=axial,
    neg_y=axial,
    pos_z=side,
    neg_z=side,
  )
}

///|
pub fn TextureNames::top_bottom(
  top : String,
  bottom : String,
  side : String,
) -> TextureNames {
  TextureNames::new(
    pos_x=side,
    neg_x=side,
    pos_y=top,
    neg_y=bottom,
    pos_z=side,
    neg_z=side,
  )
}
