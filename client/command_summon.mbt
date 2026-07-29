///|
const SUMMON_RAYCAST_MAX_DISTANCE : Double = 10.0

///|
const SUMMON_RAYCAST_STEP : Double = 0.05

///|
fn parse_summon_command(
  entity_type : StringView,
  animation : String,
  upside_down? : Bool = false,
) -> ClientCommand {
  match @entity.MobKind::from_name(entity_type) {
    Some(entity_type) => Summon(entity_type, animation, upside_down)
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
      y.to_double() + 1.0,
      z.to_double() + 0.5,
      self.player_runtime.yaw() + @math.PI,
    )
  })
}
