///|
fn noise_usage() -> String {
  "Usage: /noise [seed : uint := random] [size : [1, \{NOISE_MAX_SIZE}] := \{NOISE_DEFAULT_SIZE}] [frequency : [\{NOISE_MIN_FREQUENCY}, \{NOISE_MAX_FREQUENCY}] := \{NOISE_DEFAULT_FREQUENCY}] [octaves : [1, \{NOISE_MAX_OCTAVES}] := \{NOISE_DEFAULT_OCTAVES}] [amplitude : (0, \{NOISE_MAX_AMPLITUDE}] := \{NOISE_DEFAULT_AMPLITUDE}] [soil_depth : [\{NOISE_MIN_SOIL_DEPTH}, \{NOISE_MAX_SOIL_DEPTH}] := \{NOISE_DEFAULT_SOIL_DEPTH}]"
}

///|
/// Dispatch a chat command to its named handler.
pub fn execute_command(
  player : @player.PlayerRuntime,
  chunk : @chunk.ChunkRuntime,
  world : @level.World,
  mob_runtime : @mob.MobRuntime,
  input : String,
) -> Result[String, String] {
  let tokens = input.trim().split(" ").filter(t => !t.is_empty()).to_array()
  match tokens {
    ["/tp", ..] =>
      parse(tokens, "Usage: /tp <x> <y> <z>", s => tp_command(player, s))
    ["/rd", ..] =>
      parse(
        tokens,
        "Usage: /rd <distance: \{@chunk.MIN_RENDER_DISTANCE}..\{@chunk.MAX_RENDER_DISTANCE}>",
        s => rd_command(chunk, s),
      )
    ["/summon", ..] => {
      let position = player.crosshair_block(
        chunk_size=chunk.chunk_size,
        chunk_map=chunk.chunk_map(),
      )
      summon_command(mob_runtime, tokens, position~, yaw=player.yaw())
    }
    ["/build", ..] =>
      parse(
        tokens,
        "Usage: /build <oak | fallen_oak | cactus | nether_spire>",
        s => build_command(player, chunk, world, s),
      )
    ["/noise", ..] =>
      parse(tokens, noise_usage(), s => noise_command(player, chunk, s))
    [cmd, ..] => Err("Unknown command: \{cmd}")
    [] => Err("Command cannot be empty")
  }
}

///|
fn tp_command(
  player : @player.PlayerRuntime,
  s : ParseScope,
) -> Result[String, String] raise {
  let x = s.take_double()
  let y = s.take_double()
  let z = s.take_double()
  ignore(player.teleport(x, y, z))
  Ok("Teleported to \{x}, \{y}, \{z}")
}

///|
fn rd_command(
  chunk : @chunk.ChunkRuntime,
  s : ParseScope,
) -> Result[String, String] raise {
  let d = s.take_int(
    min=Some(@chunk.MIN_RENDER_DISTANCE),
    max=Some(@chunk.MAX_RENDER_DISTANCE),
  )
  chunk.set_render_distance(d)
  Ok("Render distance set to \{d}")
}

///|
fn build_command(
  player : @player.PlayerRuntime,
  chunk : @chunk.ChunkRuntime,
  world : @level.World,
  s : ParseScope,
) -> Result[String, String] raise {
  guard BuildType::from_name(s.take_string()) is Some(build_type) else {
    return Err("Invalid building type")
  }
  let position = player.crosshair_block(
    chunk_size=chunk.chunk_size,
    chunk_map=chunk.chunk_map(),
  )
  guard position is Some(position) else { Err("No block in sight") }
  let deltas = build_deltas(
    world.seed,
    build_type,
    position.x,
    position.y,
    position.z,
  )
  if chunk.apply_block_deltas(deltas) {
    Ok("Built structure")
  } else {
    Err("Structure extends into an unloaded chunk")
  }
}

///|
fn noise_command(
  player : @player.PlayerRuntime,
  chunk : @chunk.ChunkRuntime,
  s : ParseScope,
) -> Result[String, String] raise {
  let seed = s.take_uint(default=Some(@env.now().to_uint()))
  let size = s.take_int(
    min=Some(1),
    max=Some(NOISE_MAX_SIZE),
    default=Some(NOISE_DEFAULT_SIZE),
  )
  let frequency = s.take_double(
    min=Some(NOISE_MIN_FREQUENCY),
    max=Some(NOISE_MAX_FREQUENCY),
    default=Some(NOISE_DEFAULT_FREQUENCY),
  )
  let octaves = s.take_int(
    min=Some(1),
    max=Some(NOISE_MAX_OCTAVES),
    default=Some(NOISE_DEFAULT_OCTAVES),
  )
  let amplitude = s.take_double(
    min=Some(NOISE_MIN_FREQUENCY),
    max=Some(NOISE_MAX_AMPLITUDE),
    default=Some(NOISE_DEFAULT_AMPLITUDE),
  )
  let soil_depth = s.take_int(
    min=Some(NOISE_MIN_SOIL_DEPTH),
    max=Some(NOISE_MAX_SOIL_DEPTH),
    default=Some(NOISE_DEFAULT_SOIL_DEPTH),
  )
  let target = player
    .crosshair_block(chunk_size=chunk.chunk_size, chunk_map=chunk.chunk_map())
    .map(position => NoiseTarget::{
      position,
      seed,
      size,
      frequency,
      octaves,
      amplitude,
      soil_depth,
    })
  guard target is Some(target) else { Err("No block in sight") }
  let deltas = noise_deltas(target)
  if chunk.apply_block_deltas(deltas) {
    Ok(
      "\{target.size}x\{target.size} noise terrain placed at (\{target.center_x()}, \{target.position.y}, \{target.center_z()})",
    )
  } else {
    Err("extends into an unloaded chunk")
  }
}
