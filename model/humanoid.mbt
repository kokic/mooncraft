///|
pub type Humanoid

///|
impl Localizable for Humanoid with position(joint) {
  match joint {
    Human(Head) => @util.FVec3::new(-4.F, 24.F, -4.F).as_block_position()
    Human(Body) => @util.FVec3::new(-4.F, 24.F, -4.F).as_block_position()
    _ => default_position
  }
}
