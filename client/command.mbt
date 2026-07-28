///|
priv enum ClientCommand {
  Teleport(Double, Double, Double)
  SetRenderDistance(Int)
  Summon(@entity.MobKind, String)
  Build(BuildType)
  Invalid(String)
}

///|
pub struct CommandResult {
  success : Bool
  message : String
}

///|
const PLAYER_EYE_HEIGHT : Double = 1.65

///|
fn command_success(message : String) -> CommandResult {
  { success: true, message }
}

///|
fn command_error(message : String) -> CommandResult {
  { success: false, message }
}

///|
fn parse_finite_double(token : StringView) -> Double? {
  try {
    let value : Double = @strconv.from_str(token)
    guard !(value.is_nan() || value.is_inf()) else { None }
    Some(value)
  } catch {
    _ => None
  }
}

///|
fn parse_int(token : StringView) -> Int? {
  Some(@strconv.from_str(token)) catch {
    _ => None
  }
}

///|
fn parse_command(input : String) -> ClientCommand {
  let tokens = input
    .trim()
    .split(" ")
    .filter(token => !token.is_empty())
    .to_array()
  match tokens {
    ["/tp", x, y, z] =>
      match
        (parse_finite_double(x), parse_finite_double(y), parse_finite_double(z)) {
        (Some(x), Some(y), Some(z)) => Teleport(x, y, z)
        _ => Invalid("Usage: /tp <x> <y> <z>")
      }
    ["/tp", ..] => Invalid("Usage: /tp <x> <y> <z>")
    ["/rd", value] =>
      match parse_int(value) {
        Some(value) if value >= @render.MIN_RENDER_DISTANCE &&
          value <= @render.MAX_RENDER_DISTANCE => SetRenderDistance(value)
        _ =>
          Invalid(
            "Render distance must be between \{@render.MIN_RENDER_DISTANCE} and \{@render.MAX_RENDER_DISTANCE}",
          )
      }
    ["/rd", ..] => Invalid("Usage: /rd <number>")
    ["/summon", entity_type] => parse_summon_command(entity_type, "none")
    ["/summon", entity_type, animation] =>
      parse_summon_command(entity_type, animation.to_owned())
    ["/summon", ..] => Invalid("Usage: /summon <entity_type> [animation]")
    ["/build", build_type] => parse_build_command(build_type)
    ["/build", ..] => Invalid("Usage: /build <type>")
    [command, ..] => Invalid("Unknown command: \{command}")
    [] => Invalid("Command cannot be empty")
  }
}

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
    @block.AIR_LONG_ID,
    false,
  ).map(hit => (hit.block[0], hit.block[1], hit.block[2]))
}

///|
fn GameRuntime::execute_command(
  self : GameRuntime,
  input : String,
) -> CommandResult {
  match parse_command(input) {
    Teleport(x, y, z) => {
      ignore(self.player_runtime.teleport(x, y, z))
      command_success("Teleported to \{x}, \{y}, \{z}")
    }
    SetRenderDistance(distance) => {
      self.chunk_runtime.set_render_distance(distance)
      command_success("Render distance set to \{distance}")
    }
    Summon(kind, animation) =>
      match self.summon_target() {
        Some((x, y, z)) => {
          let spawned = @mob.spawn(
            @mob.MobSpawnRequest::new(
              @env.now().to_string(),
              kind,
              x,
              y,
              z,
              animation~,
            ),
          )
          if spawned {
            command_success("Summoned mob")
          } else {
            command_error("An entity with that id already exists")
          }
        }
        None => command_error("No block in sight")
      }
    Build(build_type) =>
      match self.crosshair_block() {
        Some((wx, wy, wz)) => {
          let deltas = self.build_deltas(build_type, wx, wy + 1, wz)
          if self.chunk_runtime.apply_block_deltas(deltas) {
            command_success("Built structure")
          } else {
            command_error("Structure extends into an unloaded chunk")
          }
        }
        None => command_error("No block in sight")
      }
    Invalid(message) => command_error(message)
  }
}
