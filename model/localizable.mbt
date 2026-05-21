///|
#warnings("-unused_constructor")
pub enum HumanoidJoint {
  Head
  Body
  LeftArm
  RightArm
  LeftLeg
  RightLeg
}

///|
#warnings("-unused_constructor")
pub enum Joint {
  Human(HumanoidJoint)
  Custom(String)
}

///|
pub trait Localizable {
  // unit: block
  position(joint : Joint) -> @util.FVec3
}

///|
pub let default_position : @util.FVec3 = @util.FVec3::new(0, 0, 0)
