///|
const PLAYER_EYE_HEIGHT : Double = 1.65

///|
fn GameRuntime::crosshair_block(self : GameRuntime) -> (Int, Int, Int)? {
  let position = self.player_runtime.position()
  let camera = @render.camera_from_yaw_pitch(
    [position[0], position[1] + PLAYER_EYE_HEIGHT, position[2]],
    self.player_runtime.yaw(),
    self.player_runtime.pitch(),
  )
  @level.raycast_blocks(
    self.chunk_map(),
    self.chunk_size,
    camera.position,
    camera.direction,
    SUMMON_RAYCAST_MAX_DISTANCE,
    SUMMON_RAYCAST_STEP,
    @schema.AIR_ID,
    false,
  ).map(hit => (hit.block[0], hit.block[1], hit.block[2]))
}

///|
fn GameRuntime::execute_command(
  game : GameRuntime,
  input : String,
) -> Result[String, String] {
  let tokens = input.trim().split(" ").filter(t => !t.is_empty()).to_array()

  match tokens {
    // 
    ["/tp", ..] =>
      parse(tokens, "Usage: /tp <x> <y> <z>", s => {
        let x = s.take_double()
        let y = s.take_double()
        let z = s.take_double()
        ignore(game.player_runtime.teleport(x, y, z))
        Ok("Teleported to \{x}, \{y}, \{z}")
      })

    //
    ["/rd", ..] =>
      parse(
        tokens,
        "Usage: /rd <distance: \{@render.MIN_RENDER_DISTANCE}..\{@render.MAX_RENDER_DISTANCE}>",
        s => {
          let d = s.take_int(
            min=Some(@render.MIN_RENDER_DISTANCE),
            max=Some(@render.MAX_RENDER_DISTANCE),
          )
          game.chunk_runtime.set_render_distance(d)
          Ok("Render distance set to \{d}")
        },
      )

    // summon an entity at the block position pointed by the crosshair
    ["/summon", ..] => summon_command(game, tokens)

    // generate a multi-block structure at the block position pointed by the crosshair
    ["/build", ..] =>
      parse(
        tokens,
        "Usage: /build <oak | fallen_oak | cactus | nether_spire>",
        s => {
          guard BuildType::from_name(s.take_string()) is Some(build_type) else {
            Err("Invalid building type")
          }
          match game.crosshair_block() {
            Some((wx, wy, wz)) => {
              let deltas = game.build_deltas(build_type, wx, wy + 1, wz)
              if game.chunk_runtime.apply_block_deltas(deltas) {
                Ok("Built structure")
              } else {
                Err("Structure extends into an unloaded chunk")
              }
            }
            None => Err("No block in sight")
          }
        },
      )

    // 
    ["/noise", ..] =>
      parse(
        tokens,
        "Usage: /noise [seed : uint := random] [size : [1, \{NOISE_MAX_SIZE}] := \{NOISE_DEFAULT_SIZE}] [frequency : [\{NOISE_MIN_FREQUENCY}, \{NOISE_MAX_FREQUENCY}] := \{NOISE_DEFAULT_FREQUENCY}] [octaves : [1, \{NOISE_MAX_OCTAVES}] := \{NOISE_DEFAULT_OCTAVES}] [amplitude : (0, \{NOISE_MAX_AMPLITUDE}] := \{NOISE_DEFAULT_AMPLITUDE}]",
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
          match game.noise_target(seed, size, frequency, octaves, amplitude) {
            Some(target) => {
              let deltas = noise_deltas(target)
              if game.chunk_runtime.apply_block_deltas(deltas) {
                Ok(
                  "\{target.size}x\{target.size} noise terrain placed at (\{target.center_x()}, \{target.y}, \{target.center_z()})",
                )
              } else {
                Err("extends into an unloaded chunk")
              }
            }
            None => Err("No block in sight")
          }
        },
      )
    
    // 
    [cmd, ..] => Err("Unknown command: \{cmd}")
    [] => Err("Command cannot be empty")
  }
}
