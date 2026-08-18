///|
/// Parse a palette entry `"base"` or `"base:state"` into (base name, state).
fn parse_palette_entry(entry : String) -> (String, UInt) {
  let parts = entry.split(":").to_array()
  guard parts.length() == 2 else { (entry, 0) }
  let state = try @string.parse_uint(parts[1]) catch {
    _ => 0U
  } noraise {
    v => v
  }
  (parts[0].to_owned(), state)
}

///|
/// Rotate a horizontal offset by `quarters` 90° steps around +Y (counter-clockwise).
fn rotate_offset(ox : Int, oz : Int, quarters : Int) -> (Int, Int) {
  match quarters {
    1 => (-oz, ox)
    2 => (-ox, -oz)
    3 => (oz, -ox)
    _ => (ox, oz)
  }
}

///|
fn mirror_offset(ox : Int, oz : Int, mirror : Bool) -> (Int, Int) {
  if mirror {
    (ox, -oz)
  } else {
    (ox, oz)
  }
}

///|
/// Remap a facing state under rotation and mirror.
fn remap_state(
  facing : @block.Facing,
  state : UInt,
  quarters : Int,
  mirror : Bool,
) -> UInt {
  match facing {
    @block.Facing::None => state
    @block.Facing::Axis => state
    @block.Facing::Horizontal => remap_horizontal(state, quarters, mirror)
    @block.Facing::Six => remap_six(state, quarters, mirror)
  }
}

///|
/// Horizontal facing: 0=+X, 1=-X, 2=+Z, 3=-Z.
fn remap_horizontal(state : UInt, quarters : Int, mirror : Bool) -> UInt {
  let (ox, oz) = match state.reinterpret_as_int() {
    1 => (-1, 0)
    2 => (0, 1)
    3 => (0, -1)
    _ => (1, 0)
  }
  let (ox, oz) = mirror_offset(ox, oz, mirror)
  let (ox, oz) = rotate_offset(ox, oz, quarters)
  if ox == 1 {
    0
  } else if ox == -1 {
    1
  } else if oz == 1 {
    2
  } else {
    3
  }
}

///|
/// Six facing: 0=+X, 1=-X, 2=+Y, 3=-Y, 4=+Z, 5=-Z.
fn remap_six(state : UInt, quarters : Int, mirror : Bool) -> UInt {
  let (ox, oy, oz) = match state.reinterpret_as_int() {
    1 => (-1, 0, 0)
    2 => (0, 1, 0)
    3 => (0, -1, 0)
    4 => (0, 0, 1)
    5 => (0, 0, -1)
    _ => (1, 0, 0)
  }
  if oy != 0 {
    state
  } else {
    let (ox, oz) = mirror_offset(ox, oz, mirror)
    let (ox, oz) = rotate_offset(ox, oz, quarters)
    if ox == 1 {
      0
    } else if ox == -1 {
      1
    } else if oz == 1 {
      4
    } else {
      5
    }
  }
}

///|
/// Place a blueprint into the world at (wx, wy, wz) aligned to its anchor.
/// `set_block` receives world coords and a resolved internal id.
pub fn place_blueprint(
  bp : Blueprint,
  set_block : (Int, Int, Int, UInt) -> Unit,
  wx : Int,
  wy : Int,
  wz : Int,
  rotation? : Int = 0,
  mirror? : Bool = false,
) -> Unit {
  let quarters = rotation % 4
  for y in 0..<bp.height() {
    for z in 0..<bp.depth() {
      for x in 0..<bp.width() {
        let idx = bp.cell(x, y, z)
        if idx < 0 {
          continue
        }
        guard idx < bp.palette.length() else { continue }
        let (name, state) = parse_palette_entry(bp.palette[idx])
        let (ox, oz) = mirror_offset(x - bp.anchor[0], z - bp.anchor[2], mirror)
        let (ox, oz) = rotate_offset(ox, oz, quarters)
        let oy = y - bp.anchor[1]
        match @block.lookup_by_name(name) {
          None => ()
          Some(block) => {
            let state = remap_state(block.facing, state, quarters, mirror)
            set_block(wx + ox, wy + oy, wz + oz, block.internal_id(state~))
          }
        }
      }
    }
  }
}

///|
/// Decode blueprint JSON text then place it. Invalid text returns an error.
pub fn place_blueprint_text(
  set_block : (Int, Int, Int, UInt) -> Unit,
  text : String,
  wx : Int,
  wy : Int,
  wz : Int,
  rotation? : Int = 0,
  mirror? : Bool = false,
) -> Result[Unit, String] {
  match Blueprint::decode(text) {
    None => Err("invalid blueprint JSON")
    Some(bp) => {
      place_blueprint(bp, set_block, wx, wy, wz, rotation~, mirror~)
      Ok(())
    }
  }
}
