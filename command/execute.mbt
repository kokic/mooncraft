///|
pub fn execute_command(
  player : @player.PlayerRuntime,
  chunk : @chunk.ChunkRuntime,
  world : @level.World,
  input : String,
) -> Result[String, String] {
  let tokens = input.trim().split(" ").filter(t => !t.is_empty()).to_array()

  match tokens {
    // teleport the player to specified coordinates
    ["/tp", ..] =>
      parse(tokens, "Usage: /tp <x> <y> <z>", s => {
        let x = s.take_double()
        let y = s.take_double()
        let z = s.take_double()
        ignore(player.teleport(x, y, z))
        Ok("Teleported to \{x}, \{y}, \{z}")
      })

    // set the render distance
    ["/rd", ..] =>
      parse(
        tokens,
        "Usage: /rd <distance: \{@chunk.MIN_RENDER_DISTANCE}..\{@chunk.MAX_RENDER_DISTANCE}>",
        s => {
          let d = s.take_int(
            min=Some(@chunk.MIN_RENDER_DISTANCE),
            max=Some(@chunk.MAX_RENDER_DISTANCE),
          )
          chunk.set_render_distance(d)
          Ok("Render distance set to \{d}")
        },
      )

    // summon an entity at the block position pointed by the crosshair
    ["/summon", ..] => {
      let position = player.crosshair_block(
        chunk_size=chunk.chunk_size,
        chunk_map=chunk.chunk_map(),
      )
      summon_command(tokens, position~, yaw=player.yaw())
    }
    // generate a multi-block structure at the block position pointed by the crosshair
    ["/build", ..] =>
      parse(
        tokens,
        "Usage: /build <oak | fallen_oak | cactus | nether_spire>",
        s => {
          guard BuildType::from_name(s.take_string()) is Some(build_type) else {
            Err("Invalid building type")
          }
          let position = player.crosshair_block(
            chunk_size=chunk.chunk_size,
            chunk_map=chunk.chunk_map(),
          )
          match position {
            Some(position) => {
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
            None => Err("No block in sight")
          }
        },
      )

    // generate noise terrain at the block position pointed by the crosshair
    ["/noise", ..] =>
      parse(
        tokens,
        "Usage: /noise [seed : uint := random] [size : [1, \{NOISE_MAX_SIZE}] := \{NOISE_DEFAULT_SIZE}] [frequency : [\{NOISE_MIN_FREQUENCY}, \{NOISE_MAX_FREQUENCY}] := \{NOISE_DEFAULT_FREQUENCY}] [octaves : [1, \{NOISE_MAX_OCTAVES}] := \{NOISE_DEFAULT_OCTAVES}] [amplitude : (0, \{NOISE_MAX_AMPLITUDE}] := \{NOISE_DEFAULT_AMPLITUDE}] [soil_depth : [\{NOISE_MIN_SOIL_DEPTH}, \{NOISE_MAX_SOIL_DEPTH}] := \{NOISE_DEFAULT_SOIL_DEPTH}]",
        s => {
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
            .crosshair_block(
              chunk_size=chunk.chunk_size,
              chunk_map=chunk.chunk_map(),
            )
            .map(position => NoiseTarget::{
              position,
              seed,
              size,
              frequency,
              octaves,
              amplitude,
              soil_depth,
            })
          match target {
            Some(target) => {
              let deltas = noise_deltas(target)
              if chunk.apply_block_deltas(deltas) {
                Ok(
                  "\{target.size}x\{target.size} noise terrain placed at (\{target.center_x()}, \{target.position.y}, \{target.center_z()})",
                )
              } else {
                Err("extends into an unloaded chunk")
              }
            }
            None => Err("No block in sight")
          }
        },
      )

    // unrecognized command
    [cmd, ..] => Err("Unknown command: \{cmd}")
    [] => Err("Command cannot be empty")
  }
}
