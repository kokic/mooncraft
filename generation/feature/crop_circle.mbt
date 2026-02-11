///|
pub let crop_circle_texts : Array[String] = [
  "Spore", "Jerry", "Yorkin", "Herobrine", "Also try Minecraft",
]

///|
const GLYPH_WIDTH : Int = 5

///|
const GLYPH_HEIGHT : Int = 7

///|
const GLYPH_ADVANCE : Int = GLYPH_WIDTH + 1

///|
const CROP_TEXT_X_MIN : Int = -64

///|
const CROP_TEXT_X_MAX : Int = 64

///|
const CROP_TEXT_Z_START : Int = -108

///|
const CROP_TEXT_Z_STEP : Int = 72

///|
const CROP_TEXT_Z_JITTER : Int = 2

///|
fn clamp01(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
fn hash01(seed : Int, salt : Int) -> Double {
  let n = seed * 110351 + salt * 92317 + 7919
  clamp01((@util.Noise::fast(n) + 1.0) * 0.5)
}

///|
fn glyph_for_code(code : UInt16) -> Array[String]? {
  match code {
    c if c == 'A' || c == 'a' =>
      Some([".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"])
    c if c == 'B' || c == 'b' =>
      Some(["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."])
    c if c == 'C' || c == 'c' =>
      Some([".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."])
    c if c == 'D' || c == 'd' =>
      Some(["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."])
    c if c == 'E' || c == 'e' =>
      Some(["#####", "#....", "#....", "####.", "#....", "#....", "#####"])
    c if c == 'F' || c == 'f' =>
      Some(["#####", "#....", "#....", "####.", "#....", "#....", "#...."])
    c if c == 'G' || c == 'g' =>
      Some([".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".###."])
    c if c == 'H' || c == 'h' =>
      Some(["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"])
    c if c == 'I' || c == 'i' =>
      Some(["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"])
    c if c == 'J' || c == 'j' =>
      Some(["..###", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."])
    c if c == 'K' || c == 'k' =>
      Some(["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"])
    c if c == 'L' || c == 'l' =>
      Some(["#....", "#....", "#....", "#....", "#....", "#....", "#####"])
    c if c == 'M' || c == 'm' =>
      Some(["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"])
    c if c == 'N' || c == 'n' =>
      Some(["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"])
    c if c == 'O' || c == 'o' =>
      Some([".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."])
    c if c == 'P' || c == 'p' =>
      Some(["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."])
    c if c == 'Q' || c == 'q' =>
      Some([".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"])
    c if c == 'R' || c == 'r' =>
      Some(["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"])
    c if c == 'S' || c == 's' =>
      Some([".####", "#....", "#....", ".###.", "....#", "....#", "####."])
    c if c == 'T' || c == 't' =>
      Some(["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."])
    c if c == 'U' || c == 'u' =>
      Some(["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."])
    c if c == 'V' || c == 'v' =>
      Some(["#...#", "#...#", "#...#", "#...#", ".#.#.", ".#.#.", "..#.."])
    c if c == 'W' || c == 'w' =>
      Some(["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"])
    c if c == 'X' || c == 'x' =>
      Some(["#...#", ".#.#.", "..#..", "..#..", "..#..", ".#.#.", "#...#"])
    c if c == 'Y' || c == 'y' =>
      Some(["#...#", ".#.#.", "..#..", "..#..", "..#..", "..#..", "..#.."])
    c if c == 'Z' || c == 'z' =>
      Some(["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"])
    '0' => Some([".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."])
    '1' => Some(["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."])
    '2' => Some([".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"])
    '3' => Some(["####.", "....#", "...#.", "..##.", "....#", "#...#", ".###."])
    '4' => Some(["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."])
    '5' => Some(["#####", "#....", "####.", "....#", "....#", "#...#", ".###."])
    '6' => Some([".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."])
    '7' => Some(["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."])
    '8' => Some([".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."])
    '9' => Some([".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."])
    _ => None
  }
}

///|
fn text_pixel_width(text : String) -> Int {
  let mut width = 0
  for i in 0..<text.length() {
    let glyph_width = match glyph_for_code(text[i]) {
      Some(_) => GLYPH_ADVANCE
      None => 3
    }
    width = width + glyph_width
  }
  if width > 0 {
    width - 1
  } else {
    0
  }
}

///|
fn place_pixel_text(
  set_block : (Int, Int, Int, UInt) -> Unit,
  text : String,
  start_x : Int,
  y : Int,
  start_z : Int,
  filler : @block.BlockId,
) -> Unit {
  let mut cursor = 0
  for i in 0..<text.length() {
    match glyph_for_code(text[i]) {
      None => cursor = cursor + 3
      Some(glyph) => {
        for gz in 0..<GLYPH_HEIGHT {
          let row = glyph[gz]
          for gx in 0..<GLYPH_WIDTH {
            if row[gx] == '#' {
              set_block(start_x + cursor + gx, y, start_z + gz, filler)
            }
          }
        }
        cursor = cursor + GLYPH_ADVANCE
      }
    }
  }
}

///|
/// Place seed-stable crop-circle text once per configured line.
/// Caller can invoke per chunk; set_block should clip to local chunk.
pub fn place_crop_circle_texts_flat(
  set_block : (Int, Int, Int, UInt) -> Unit,
  world_seed : Int,
  surface_y : Int,
  filler? : @block.BlockId = @block.lookup_by_name("grass_path").unwrap().id,
) -> Unit {
  for i in 0..<crop_circle_texts.length() {
    let text = crop_circle_texts[i]
    let width = text_pixel_width(text)
    let x_span = CROP_TEXT_X_MAX - CROP_TEXT_X_MIN - width
    let x_rand = (hash01(world_seed, i * 97 + 17) * x_span.to_double())
      .floor()
      .to_int()
    let x = CROP_TEXT_X_MIN + x_rand
    let lane_z = CROP_TEXT_Z_START + i * CROP_TEXT_Z_STEP
    let jitter_span = CROP_TEXT_Z_JITTER * 2 + 1
    let z_jitter = (hash01(world_seed, i * 131 + 59) * jitter_span.to_double())
      .floor()
      .to_int() -
      CROP_TEXT_Z_JITTER
    let z = lane_z + z_jitter
    place_pixel_text(set_block, text, x, surface_y, z, filler)
  }
}
