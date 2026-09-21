///|
fn heal_command(
  player : @player.PlayerRuntime,
  s : ParseScope,
) -> Result[String, String] raise {
  let amount = s.take_double(
    min=Some(0.0),
    max=Some(@player.MAX_HEALTH),
    default=Some(@player.MAX_HEALTH),
  )
  ignore(player.heal(amount))
  Ok("Healed \{amount} health")
}

///|
fn damage_command(
  player : @player.PlayerRuntime,
  s : ParseScope,
) -> Result[String, String] raise {
  let amount = s.take_double(min=Some(0.0), default=Some(1.0))
  ignore(player.apply_damage(amount))
  Ok("Dealt \{amount} damage")
}

///|
fn gamemode_command(
  player : @player.PlayerRuntime,
  s : ParseScope,
) -> Result[String, String] raise {
  let mode = s.take_string()
  guard mode == "creative" || mode == "survival" || mode == "spectator" else {
    return Err("Game mode must be creative, survival, or spectator")
  }
  ignore(player.set_game_mode(mode))
  Ok("Game mode set to \{mode}")
}
