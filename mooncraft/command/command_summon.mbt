///|
fn summon_command(
  mob_runtime : @mob.MobRuntime,
  tokens : Array[StringView],
  position~ : @schema.BlockPos?,
  yaw~ : Double,
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

    let target = position.map(p => {
      (
        p.x.to_double() + 0.5,
        p.y.to_double() + 1,
        p.z.to_double() + 0.5,
        yaw + @math.PI,
      )
    })
    match target {
      Some((x, y, z, yaw)) =>
        if mob_runtime.spawn(
            @mob.MobSpawnRequest::new(
              @env.now().to_string(),
              kind,
              x,
              y,
              z,
              animation~,
              upside_down~,
              yaw~,
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
