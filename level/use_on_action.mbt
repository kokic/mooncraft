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
fn intersects(
  a_min_x : Double,
  a_min_y : Double,
  a_min_z : Double,
  a_max_x : Double,
  a_max_y : Double,
  a_max_z : Double,
  b_min_x : Double,
  b_min_y : Double,
  b_min_z : Double,
  b_max_x : Double,
  b_max_y : Double,
  b_max_z : Double,
) -> Bool {
  a_max_x > b_min_x &&
  a_min_x < b_max_x &&
  a_max_y > b_min_y &&
  a_min_y < b_max_y &&
  a_max_z > b_min_z &&
  a_min_z < b_max_z
}

///|
fn can_place_block(
  long_id : UInt,
  player_pos : Array[Double],
  entity_height : Double,
  entity_radius : Double,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Bool {
  if long_id == @block.AIR_LONG_ID {
    return true
  }
  if player_pos.length() < 3 {
    return true
  }
  match @block.get_shape_desc(long_id) {
    None => false
    Some(desc) => {
      let px = player_pos[0]
      let py = player_pos[1]
      let pz = player_pos[2]
      let ent_min_x = px - entity_radius
      let ent_max_x = px + entity_radius
      let ent_min_y = py
      let ent_max_y = py + entity_height
      let ent_min_z = pz - entity_radius
      let ent_max_z = pz + entity_radius
      for box in desc.boxes {
        let b_min_x = wx.to_double() + box.min[0].to_double()
        let b_max_x = wx.to_double() + box.max[0].to_double()
        let b_min_y = wy.to_double() + box.min[1].to_double()
        let b_max_y = wy.to_double() + box.max[1].to_double()
        let b_min_z = wz.to_double() + box.min[2].to_double()
        let b_max_z = wz.to_double() + box.max[2].to_double()
        if intersects(
            ent_min_x, ent_min_y, ent_min_z, ent_max_x, ent_max_y, ent_max_z, b_min_x,
            b_min_y, b_min_z, b_max_x, b_max_y, b_max_z,
          ) {
          return false
        }
      }
      true
    }
  }
}

///|
pub fn apply_use_on_action(
  chunk_map : @ffi.JsValue,
  size : Int,
  action : @item.UseOnAction,
  player_pos? : Array[Double] = [],
  entity_height? : Double = 0,
  entity_radius? : Double = 0,
) -> Array[String] {
  match action {
    @item.UseOnAction::None => []
    @item.UseOnAction::Batch(actions) => {
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
      expected=expected_name,
      neo=new_name,
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
    @item.UseOnAction::PlaceBlock(
      target_wx~,
      target_wy~,
      target_wz~,
      place_wx~,
      place_wy~,
      place_wz~,
      name~,
      require_air~,
    ) => {
      if require_air && !is_air_at(chunk_map, size, place_wx, place_wy, place_wz) {
        []
      } else {
        match resolve_block_long_id(name) {
          None => []
          Some(base_id) => {
            let block = [target_wx, target_wy, target_wz]
            let prev = [place_wx, place_wy, place_wz]
            let placement_state = @block.compute_placement_state(base_id, block, prev)
            let (raw_id, _) = @util.unpack_long_id(base_id)
            let long_id = @util.pack_long_id(raw_id, placement_state)
            if can_place_block(
                long_id,
                player_pos,
                entity_height,
                entity_radius,
                place_wx,
                place_wy,
                place_wz,
              ) {
              set_block_id(chunk_map, size, place_wx, place_wy, place_wz, long_id)
            } else {
              []
            }
          }
        }
      }
    }
  }
}

///|
pub fn apply_use_on_action_with_player(
  chunk_map : @ffi.JsValue,
  size : Int,
  action : @item.UseOnAction,
  player_pos : Array[Double],
  entity_height : Double,
  entity_radius : Double,
) -> Array[String] {
  apply_use_on_action(
    chunk_map,
    size,
    action,
    player_pos=player_pos,
    entity_height=entity_height,
    entity_radius=entity_radius,
  )
}
