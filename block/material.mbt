///|
pub(all) enum Material {
  TintedLeaf
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
    Tinted(r, g, b, a) => (r, g, b, a)
    _ => (1.0F, 1.0F, 1.0F, 1.0F)
  }
}
