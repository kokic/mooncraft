///|
/// Input snapshot for player movement.
pub struct MoveInput {
  forward : Bool
  back : Bool
  left : Bool
  right : Bool
  up : Bool
  down : Bool
  sprint : Bool
  fast : Bool
}

///|
pub fn MoveInput::new(
  forward? : Bool = false,
  back? : Bool = false,
  left? : Bool = false,
  right? : Bool = false,
  up? : Bool = false,
  down? : Bool = false,
  sprint? : Bool = false,
  fast? : Bool = false,
) -> MoveInput {
  { forward, back, left, right, up, down, sprint, fast, }
}

///|
fn PlayerRuntime::clear_input(self : PlayerRuntime) -> Unit {
  self.move_intent = MoveInput::new()
  self.yaw_intent = 0.0
  self.pitch_intent = 0.0
}
