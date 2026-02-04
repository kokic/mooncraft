///|
pub(all) enum Opacity {
  /// Render all solid rendering blocks
  Solid
  /// Render various transparent blocks
  Cutout
  /// Render various translucent blocks [TODO]
  Translucent
}

///|
pub fn Opacity::enable_occlusion_culling(opacity : Opacity) -> Bool {
  match opacity {
    Solid => true
    _ => false
  }
}

///|
/// 0 ~ 15
pub fn Opacity::light_blocker(opacity : Opacity) -> Int {
  match opacity {
    Cutout => 0
    Translucent => 8
    Solid => 15
  }
}
