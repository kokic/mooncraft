///|
fn resolve_block_long_id(name : String) -> UInt? {
  match @block.lookup_by_name(name) {
    Some(block) => Some(block.long_id())
    None => None
  }
}

///|
fn is_air_at(chunk_map : @ffi.JsValue, size : Int, wx : Int, wy : Int, wz : Int) -> Bool {
  match get_block_id(chunk_map, size, wx, wy, wz) {
    Some(id) => id == @block.AIR_LONG_ID
    None => false
  }
}

///|
pub fn apply_use_on_action(
  chunk_map : @ffi.JsValue,
  size : Int,
  action : @item.UseOnAction,
) -> Array[String] {
  match action {
    @item.UseOnAction::None => []
    @item.UseOnAction::Batch(actions~) => {
      let out : Array[String] = []
      for sub in actions {
        for key in apply_use_on_action(chunk_map, size, sub) {
          out.push(key)
        }
      }
      out
    }
    @item.UseOnAction::ReplaceBlock(
      wx~,
      wy~,
      wz~,
      expected_name~,
      new_name~,
      require_above_air~,
    ) => {
      let current = get_block_id(chunk_map, size, wx, wy, wz)
      match current {
        None => []
        Some(current_id) => {
          if require_above_air && !is_air_at(chunk_map, size, wx, wy + 1, wz) {
            []
          } else {
            let expected_ok = match expected_name {
              None => true
              Some(name) =>
                match resolve_block_long_id(name) {
                  Some(expected_id) => expected_id == current_id
                  None => false
                }
            }
            if !expected_ok {
              []
            } else {
              match resolve_block_long_id(new_name) {
                None => []
                Some(new_id) => set_block_id(chunk_map, size, wx, wy, wz, new_id)
              }
            }
          }
        }
      }
    }
  }
}
