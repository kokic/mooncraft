///|
fn resolve_block_internal_id(name : String) -> UInt? {
  @block.lookup_by_name(name).map(block => block.internal_id())
}

///|
fn block_name_matches(
  internal_id : UInt,
  selector : @item.BlockSelector,
) -> Bool {
  @block.lookup_by_internal_id(internal_id).map_or(false, block => {
    selector.matches(block.name)
  })
}

///|
fn resolve_block_internal_id_by_selector(
  selector : @item.BlockSelector,
) -> UInt? {
  let mut found : UInt? = None
  for block in @block.blocks {
    guard selector.matches(block.name) else { continue }
    guard found is None else {
      // Ambiguous predicate: refuse replacement to keep behavior deterministic.
      return None
    }
    found = Some(block.internal_id())
  }
  found
}

///|
/// Apply placement/replacement actions, retaining actor context within batches.
pub fn apply_use_on_action(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  action : @item.UseOnAction,
  player_pos? : Array[Double] = [],
  entity_height? : Double = 0,
  entity_radius? : Double = 0,
) -> Array[String] {
  BlockInteraction::new(
    chunk_map, size, player_pos~, entity_height~, entity_radius~,
  ).apply_use_on_action(action)
}

///|
fn BlockInteraction::apply_use_on_action(
  self : BlockInteraction,
  action : @item.UseOnAction,
) -> Array[String] {
  match action {
    @item.UseOnAction::None => []
    @item.UseOnAction::Batch(actions) => {
      let out : Array[String] = []
      for sub in actions {
        for key in self.apply_use_on_action(sub) {
          out.push(key)
        }
      }
      out
    }
    @item.UseOnAction::ReplaceBlock(
      wx~,
      wy~,
      wz~,
      expected=expected_predicate,
      neo=new_predicate,
      require_above_air~
    ) => {
      let current = self.block_at(wx, wy, wz)
      guard current is Some(current_id) else { [] }
      guard !require_above_air || self.is_air_at(wx, wy + 1, wz) else {
        []
      }
      guard block_name_matches(current_id, expected_predicate) else { [] }
      guard resolve_block_internal_id_by_selector(new_predicate) is Some(new_id) else {
        []
      }
      self.set_block(wx, wy, wz, new_id)
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
      click~
    ) => {
      guard !require_air ||
        self.can_replace_at(place_wx, place_wy, place_wz) else {
        []
      }
      guard resolve_block_internal_id(name) is Some(base_id) else { [] }
      let block = [target_wx, target_wy, target_wz]
      let prev = [place_wx, place_wy, place_wz]
      let placement_state = @block.compute_placement_state(
        base_id,
        block,
        prev,
        player_pos=self.player_pos,
        click~,
      )
      let raw_id = @schema.decode_block_id(base_id)
      let internal_id = @schema.encode_variant(raw_id, placement_state)
      guard @block.can_place_block(
        internal_id,
        self.player_pos,
        self.entity_height,
        self.entity_radius,
        place_wx,
        place_wy,
        place_wz,
      ) else {
        []
      }
      self.set_block(place_wx, place_wy, place_wz, internal_id)
    }
  }
}

///|
pub fn apply_use_on_action_with_player(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
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
    player_pos~,
    entity_height~,
    entity_radius~,
  )
}
