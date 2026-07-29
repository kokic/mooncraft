///|
const SUMMON_RAYCAST_MAX_DISTANCE : Double = 10.0

///|
const SUMMON_RAYCAST_STEP : Double = 0.05

///|
fn parse_summon_command(tokens : Array[StringView]) -> ClientCommand {
  let invalid = Invalid(
    "Usage: /summon <entity_type> [animation] [sx] [sy] [sz]",
  )
  guard tokens.length() >= 2 else { return invalid }
  let entity_type = tokens[1]
  let extras = tokens[2:]
  let mut animation = "none"
  let mut upside_down = false
  let mut scale : Array[Double]? = None
  match extras.length() {
    0 => ()
    1 =>
      if extras[0] == "jeb_" {
        upside_down = true
      } else {
        match parse_finite_double(extras[0]) {
          Some(s) => scale = Some([s, s, s])
          None => animation = extras[0].to_owned()
        }
      }
    3 =>
      match parse_finite_double3(extras[0], extras[1], extras[2]) {
        Some((sx, sy, sz)) => scale = Some([sx, sy, sz])
        _ => return invalid
      }
    4 =>
      match parse_finite_double3(extras[0], extras[1], extras[2]) {
        Some((sx, sy, sz)) => {
          animation = extras[0].to_owned()
          scale = Some([sx, sy, sz])
        }
        _ => return invalid
      }
    _ => return invalid
  }
  match @entity.MobKind::from_name(entity_type) {
    Some(kind) => Summon(kind, animation, upside_down, scale)
    None => Invalid("Entity type must be a supported mob")
  }
}

///|
fn GameRuntime::summon_target(
  self : GameRuntime,
) -> (Double, Double, Double, Double)? {
  self
  .crosshair_block()
  .map(point => {
    let (x, y, z) = point
    (
      x.to_double() + 0.5,
      y.to_double() + 1,
      z.to_double() + 0.5,
      self.player_runtime.yaw() + @math.PI,
    )
  })
}
