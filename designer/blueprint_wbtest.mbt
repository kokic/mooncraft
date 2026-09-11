///|
fn collected_blocks() -> (Array[Array[Int]], (Int, Int, Int, UInt) -> Unit) {
  let out : Array[Array[Int]] = []
  let set_block = (x : Int, y : Int, z : Int, id : UInt) => {
    out.push([x, y, z, id.reinterpret_as_int()])
  }
  (out, set_block)
}

///|
test "blueprint encode/decode round-trips" {
  let bp = Blueprint::new("test_well", [5, 4, 5], [2, 0, 2], palette=[
    "cobblestone", "water",
  ])
  bp.set_cell(0, 0, 0, 0)
  bp.set_cell(2, 1, 2, 1)
  bp.set_cell(4, 3, 4, 0)
  let decoded = Blueprint::decode(bp.encode()).unwrap()
  @test.assert_eq(decoded.name, "test_well")
  @test.assert_eq(decoded.width(), 5)
  @test.assert_eq(decoded.height(), 4)
  @test.assert_eq(decoded.depth(), 5)
  @test.assert_eq(decoded.cell(0, 0, 0), 0)
  @test.assert_eq(decoded.cell(2, 1, 2), 1)
  @test.assert_eq(decoded.cell(4, 3, 4), 0)
  @test.assert_eq(decoded.cell(1, 0, 1), -1)
  @test.assert_eq(decoded.palette[0], "cobblestone")
  @test.assert_eq(decoded.palette[1], "water")
}

///|
test "blueprint decode rejects malformed input" {
  @test.assert_eq(Blueprint::decode("not json") is None, true)
  @test.assert_eq(Blueprint::decode("{}") is None, true)
}

///|
test "blueprint trim_empty crops margins and shifts anchor" {
  let bp = Blueprint::new("test", [7, 3, 7], [3, 1, 3], palette=["stone"])
  // Filled block spans local x 2..4, y 0..2, z 3..5.
  bp.set_cell(2, 0, 3, 0)
  bp.set_cell(3, 1, 4, 0)
  bp.set_cell(4, 2, 5, 0)
  let trimmed = bp.trim_empty()
  @test.assert_eq(trimmed.width(), 3)
  @test.assert_eq(trimmed.height(), 3)
  @test.assert_eq(trimmed.depth(), 3)
  @test.assert_eq(trimmed.anchor[0], 1)
  @test.assert_eq(trimmed.anchor[1], 1)
  @test.assert_eq(trimmed.anchor[2], 0)
  @test.assert_eq(trimmed.cell(0, 0, 0), 0)
  @test.assert_eq(trimmed.cell(2, 2, 2), 0)
  @test.assert_eq(trimmed.palette[0], "stone")
}

///|
test "place_blueprint writes correct world coordinates" {
  let bp = Blueprint::new("test", [3, 1, 1], [1, 0, 0], palette=["stone"])
  bp.set_cell(0, 0, 0, 0)
  bp.set_cell(2, 0, 0, 0)
  let (calls, set_block) = collected_blocks()
  place_blueprint(bp, set_block, 10, 20, 30)
  @test.assert_eq(calls.length(), 2)
  @test.assert_eq(calls[0][0], 9)
  @test.assert_eq(calls[0][1], 20)
  @test.assert_eq(calls[0][2], 30)
  @test.assert_eq(calls[1][0], 11)
  @test.assert_eq(calls[1][1], 20)
  @test.assert_eq(calls[1][2], 30)
  let stone_id = @block.lookup_by_name("stone").unwrap().internal_id()
  @test.assert_eq(calls[0][3], stone_id.reinterpret_as_int())
}

///|
test "parse_palette_entry splits name and state" {
  let (name, state) = parse_palette_entry("classic.oak_log:2")
  @test.assert_eq(name, "classic.oak_log")
  @test.assert_eq(state, 2U)
  let (name0, state0) = parse_palette_entry("stone")
  @test.assert_eq(name0, "stone")
  @test.assert_eq(state0, 0U)
}

///|
test "place_blueprint applies palette state to internal id" {
  let bp = Blueprint::new("log", [1, 1, 1], [0, 0, 0], palette=[
    "classic.oak_log:1",
  ])
  bp.set_cell(0, 0, 0, 0)
  let (calls, set_block) = collected_blocks()
  place_blueprint(bp, set_block, 0, 0, 0)
  let expected = @block.lookup_by_name("classic.oak_log")
    .unwrap()
    .internal_id(state=1)
  @test.assert_eq(calls[0][3], expected.reinterpret_as_int())
}

///|
test "remap_horizontal rotates facing states" {
  // 0=+X rotates to +Z under a single 90° counter-clockwise turn.
  @test.assert_eq(remap_horizontal(0U, 1, false), 2U)
  // Two turns flip the facing.
  @test.assert_eq(remap_horizontal(0U, 2, false), 1U)
  // Three turns reach -Z.
  @test.assert_eq(remap_horizontal(0U, 3, false), 3U)
  // Mirror flips Z facing (state 2=+Z -> 3=-Z); X facing is unchanged.
  @test.assert_eq(remap_horizontal(0U, 0, true), 0U)
  @test.assert_eq(remap_horizontal(2U, 0, true), 3U)
}

///|
test "remap_six rotates horizontal facing states and keeps vertical" {
  // +X -> +Z under one turn; +Y is unaffected.
  @test.assert_eq(remap_six(0U, 1, false), 4U)
  @test.assert_eq(remap_six(2U, 1, false), 2U)
  @test.assert_eq(remap_six(3U, 2, false), 3U)
}

///|
test "place_blueprint_text decodes then places" {
  let bp = Blueprint::new("text", [1, 1, 1], [0, 0, 0], palette=["dirt"])
  bp.set_cell(0, 0, 0, 0)
  let (calls, set_block) = collected_blocks()
  let result = place_blueprint_text(set_block, bp.encode(), 5, 6, 7)
  @test.assert_eq(result, Ok(()))
  @test.assert_eq(calls.length(), 1)
  @test.assert_eq(calls[0][0], 5)
  @test.assert_eq(calls[0][1], 6)
  @test.assert_eq(calls[0][2], 7)
  let bad = place_blueprint_text(set_block, "bad", 0, 0, 0)
  @test.assert_eq(bad, Err("invalid blueprint JSON"))
}
