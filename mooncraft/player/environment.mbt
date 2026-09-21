///|
/// Whether any block cell overlapping the player body satisfies `matches`.
fn player_body_overlaps(
  position : Array[Double],
  entity_height : Double,
  entity_radius : Double,
  matches : (Int, Int, Int) -> Bool,
) -> Bool {
  let min_x = (position[0] - entity_radius).floor().to_int()
  let max_x = (position[0] + entity_radius).floor().to_int()
  let min_y = position[1].floor().to_int()
  let max_y = (position[1] + entity_height * 0.85).floor().to_int()
  let min_z = (position[2] - entity_radius).floor().to_int()
  let max_z = (position[2] + entity_radius).floor().to_int()
  for wx in min_x..<=max_x {
    for wy in min_y..<=max_y {
      for wz in min_z..<=max_z {
        if matches(wx, wy, wz) {
          return true
        }
      }
    }
  }
  false
}

///|
fn is_player_in_water(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  px : Double,
  py : Double,
  pz : Double,
  entity_height : Double,
  entity_radius : Double,
) -> Bool {
  player_body_overlaps([px, py, pz], entity_height, entity_radius, (wx, wy, wz) => {
    @level.is_water_at(chunk_map, size, wx, wy, wz)
  })
}

///|
fn is_player_in_lava(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  px : Double,
  py : Double,
  pz : Double,
  entity_height : Double,
  entity_radius : Double,
) -> Bool {
  player_body_overlaps([px, py, pz], entity_height, entity_radius, (wx, wy, wz) => {
    @level.is_lava_at(chunk_map, size, wx, wy, wz)
  })
}

///|
fn is_player_touching_cactus(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  px : Double,
  py : Double,
  pz : Double,
  entity_height : Double,
  entity_radius : Double,
) -> Bool {
  player_body_overlaps([px, py, pz], entity_height, entity_radius, (wx, wy, wz) => {
    @level.is_cactus_at(chunk_map, size, wx, wy, wz)
  })
}

///|
fn is_head_in_water(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  position : Array[Double],
  entity_height : Double,
) -> Bool {
  @level.is_water_at(
    chunk_map,
    size,
    position[0].floor().to_int(),
    (position[1] + entity_height * 0.9).floor().to_int(),
    position[2].floor().to_int(),
  )
}

///|
/// Build the hazard and motion context for one survival tick.
fn collect_vitals_context(
  chunk_map : @hashmap.HashMap[String, Array[UInt]],
  size : Int,
  position : Array[Double],
  entity_height : Double,
  entity_radius : Double,
  world_min_y : Int,
  game_mode : String,
  moved : Bool,
  sprinted : Bool,
  jumped : Bool,
  on_ground : Bool,
  fall_distance : Double,
) -> VitalsContext {
  let px = position[0]
  let py = position[1]
  let pz = position[2]
  {
    game_mode,
    moved,
    sprinted,
    jumped,
    on_ground,
    fall_distance,
    head_in_water: is_head_in_water(chunk_map, size, position, entity_height),
    in_lava: is_player_in_lava(
      chunk_map, size, px, py, pz, entity_height, entity_radius,
    ),
    on_cactus: is_player_touching_cactus(
      chunk_map, size, px, py, pz, entity_height, entity_radius,
    ),
    below_world: py < world_min_y.to_double(),
  }
}
