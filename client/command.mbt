///|
priv enum ClientCommand {
  Teleport(Double, Double, Double)
  SetRenderDistance(Int)
  Invalid(String)
}

///|
pub struct CommandResult {
  success : Bool
  message : String
}

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
    if value.is_nan() || value.is_inf() {
      None
    } else {
      Some(value)
    }
  } catch {
    _ => None
  }
}

///|
fn parse_int(token : StringView) -> Int? {
  try {
    let value : Int = @strconv.from_str(token)
    Some(value)
  } catch {
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
    [command, ..] => Invalid("Unknown command: \{command}")
    [] => Invalid("Command cannot be empty")
  }
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
    Invalid(message) => command_error(message)
  }
}
