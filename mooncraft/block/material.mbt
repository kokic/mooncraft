///|
pub(all) enum Material {
  TintedLeaf
  Water
  Normal
  Tinted(Float, Float, Float, Float)
}

///|
/// Construct a tinted material from RGBA.
pub fn Material::tinted(rgba : @util.Rgba) -> Material {
  let (r, g, b, a) = rgba
  Material::Tinted(r, g, b, a)
}

///|
/// Resolve per-vertex tint (rgb) and alpha.
/// Leaves use a dedicated shader tint, so default to white here.
pub fn Material::tint(material : Material) -> @util.Rgba {
  match material {
    Water => (1.0F, 1.0F, 1.0F, 0.62F)
    Tinted(r, g, b, a) => (r, g, b, a)
    _ => (1.0F, 1.0F, 1.0F, 1.0F)
  }
}

///|
pub fn Material::is_water(material : Material) -> Bool {
  material is Water
}
