///|
/// The palette label ("name" or "name:state") of the block at (wx, wy, wz),
/// or `None` for air, missing, or unregistered blocks.
fn block_label_at(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> String? {
  guard @level.get_block_id(chunk_map, size, wx, wy, wz) is Some(v) else {
    None
  }
  guard v != @schema.AIR_ID else { None }
  guard @block.lookup_by_internal_id(@schema.decode_block_id(v) * 256)
    is Some(base) else {
    None
  }
  let state = @schema.decode_state(v)
  if state == 0U {
    Some(base.name)
  } else {
    Some("\{base.name}:\{state}")
  }
}

///|
/// The palette index for `label`, inserting it when first seen.
fn palette_index_for(
  palette_idx : @hashmap.HashMap[String, Int],
  palette : Array[String],
  label : String,
) -> Int {
  match palette_idx.get(label) {
    Some(i) => i
    None => {
      let i = palette.length()
      palette.push(label)
      palette_idx[label] = i
      i
    }
  }
}

///|
/// Capture a world region into a blueprint. `floor_y` marks a layer that is
/// excluded from the result (the design canvas ground). Air cells become `-1`;
/// the bounding box is trimmed and the anchor set to the region minimum corner.
pub fn capture_design_world(
  name : String,
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  min_x : Int,
  min_y : Int,
  min_z : Int,
  max_x : Int,
  max_y : Int,
  max_z : Int,
  floor_y : Int,
) -> @designer.Blueprint {
  let width = max_x - min_x + 1
  let height = max_y - min_y + 1
  let depth = max_z - min_z + 1
  let palette_idx : @hashmap.HashMap[String, Int] = @hashmap.HashMap([])
  let palette : Array[String] = []
  let entries = Array::make(width * height * depth, -1)
  for wy in min_y..<=max_y {
    guard wy != floor_y else { continue }
    for wz in min_z..<=max_z {
      for wx in min_x..<=max_x {
        let lx = wx - min_x
        let ly = wy - min_y
        let lz = wz - min_z
        let linear = (ly * depth + lz) * width + lx
        guard block_label_at(chunk_map, size, wx, wy, wz) is Some(label) else {
          continue
        }
        entries[linear] = palette_index_for(palette_idx, palette, label)
      }
    }
  }
  let bp = @designer.Blueprint::new(
    name,
    [width, height, depth],
    [0, 0, 0],
    palette~,
  )
  for i in 0..<entries.length() {
    if entries[i] >= 0 {
      bp.cells[i] = entries[i]
    }
  }
  let trimmed = bp.trim_empty()
  // The anchor is the blueprint's minimum corner, so loading at (wx, wy, wz)
  // aligns that corner to the requested world position.
  trimmed.anchor[0] = 0
  trimmed.anchor[1] = 0
  trimmed.anchor[2] = 0
  trimmed
}

///|
/// Place a blueprint encoded as JSON into the world, aligned so its anchor sits
/// at (wx, wy, wz). Returns an error message when the text is not a blueprint.
pub fn load_blueprint_into_world(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  text : String,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Result[Unit, String] {
  let set_block = (x : Int, y : Int, z : Int, id : UInt) => {
    ignore(@level.set_block_id(chunk_map, size, x, y, z, id))
  }
  @designer.place_blueprint_text(set_block, text, wx, wy, wz)
}

///|
/// Clear every design-world block except the grass floor layer.
pub fn reset_design_world(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
) -> Unit {
  let half_x = @level.DESIGN_WORLD_X_SIZE / 2
  let half_z = @level.DESIGN_WORLD_Z_SIZE / 2
  for wy in @level.DESIGN_MIN_Y..<=@level.DESIGN_MAX_Y {
    guard wy != @level.DESIGN_MIN_Y else { continue }
    for wz in -half_z..<half_z {
      for wx in -half_x..<half_x {
        ignore(@level.set_block_id(chunk_map, size, wx, wy, wz, @schema.AIR_ID))
      }
    }
  }
}

///|
/// Publish the browser-side blueprint authoring API for the design world.
pub fn register_designer_api(game : GameRuntime) -> Unit {
  @ffi.cast_global_set("mcExportBlueprint", (
    name : String,
    x0 : Int,
    y0 : Int,
    z0 : Int,
    x1 : Int,
    y1 : Int,
    z1 : Int,
  ) => {
    capture_design_world(
      name,
      game.chunk_runtime.chunk_map(),
      game.chunk_size,
      x0,
      y0,
      z0,
      x1,
      y1,
      z1,
      @level.DESIGN_MIN_Y,
    ).encode()
  })
  @ffi.cast_global_set("mcLoadBlueprint", (
    text : String,
    wx : Int,
    wy : Int,
    wz : Int,
  ) => {
    load_blueprint_into_world(
      game.chunk_runtime.chunk_map(),
      game.chunk_size,
      text,
      wx,
      wy,
      wz,
    )
    is Ok(_)
  })
  @ffi.cast_global_set("mcResetDesignWorld", () => {
    reset_design_world(game.chunk_runtime.chunk_map(), game.chunk_size)
  })
}
