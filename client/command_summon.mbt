///|
const SUMMON_RAYCAST_MAX_DISTANCE : Double = 10.0

///|
const SUMMON_RAYCAST_STEP : Double = 0.05

///|
fn summon_command(
  game : GameRuntime,
  tokens : Array[StringView],
) -> Result[String, String] {
  let usage = "Usage: /summon <entity_type> [animation] [sx] [sy] [sz]"
  parse(tokens, usage, s => {
    guard @entity.MobKind::from_name(s.take_string()) is Some(kind) else {
      return Err("Entity type must be a supported mob")
    }
    let animation = s.take_string(default=Some("none"))
    let upside_down = animation == "jeb_"
    let animation = if upside_down { "none" } else { animation }
    
    let scale = [
      s.take_double(default=Some(1)), // scale X
      s.take_double(default=Some(1)), // scale Y
      s.take_double(default=Some(1)), // scale Z
    ]
    match game.summon_target() {
      Some((x, y, z, mob_yaw)) =>
        if @mob.spawn(
            @mob.MobSpawnRequest::new(
              @env.now().to_string(),
              kind,
              x,
              y,
              z,
              animation~,
              upside_down~,
              yaw=mob_yaw,
              scale,
            ),
          ) {
          Ok("Summoned mob")
        } else {
          Err("An entity with that id already exists")
        }
      None => Err("No block in sight")
    }
  })
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
