///|
extern "js" fn jnav_store(entity_id : String, path : Array[Array[Int]]) -> Unit =
  #| (entityId, path) => {
  #|   console.log("[nav] jnav_store", entityId, "len:", path.length);
  #|   window["__mc_nav_path_" + entityId] = path;
  #|   window["__mc_nav_step_" + entityId] = 0;
  #|   window["__mc_nav_elapsed_" + entityId] = 0;
  #| }

///|
extern "js" fn jnav_clear(entity_id : String) -> Unit =
  #| (entityId) => {
  #|   delete window["__mc_nav_path_" + entityId];
  #|   delete window["__mc_nav_step_" + entityId];
  #|   delete window["__mc_nav_elapsed_" + entityId];
  #| }

///|
extern "js" fn jnav_tick(
  entity_id : String,
  delta : Double,
) -> @ffi.JsValue =
  #| (entityId, delta) => {
  #|   const path = window["__mc_nav_path_" + entityId];
  #|   if (!Array.isArray(path)) return null;
  #|   let step = window["__mc_nav_step_" + entityId] | 0;
  #|   let elapsed = (window["__mc_nav_elapsed_" + entityId] | 0) + delta;
  #|   while (elapsed >= 0.25 && step + 1 < path.length) {
  #|     elapsed -= 0.25;
  #|     step += 1;
  #|   }
  #|   const arrived = step + 1 >= path.length;
  #|   if (arrived) { step = path.length - 1; elapsed = 0; }
  #|   window["__mc_nav_step_" + entityId] = step;
  #|   window["__mc_nav_elapsed_" + entityId] = elapsed;
  #|   if (arrived) {
  #|     console.log("[nav] tick arrived at goal", entityId);
  #|     return null;
  #|   }
  #|   const cur = path[step];
  #|   const next = path[Math.min(step + 1, path.length - 1)];
  #|   console.log("[nav] jnav_tick step:", step, "cur:", cur, "next:", next);
  #|   if (!Array.isArray(cur) || cur.length < 3) return null;
  #|   if (!Array.isArray(next) || next.length < 3) return null;
  #|   return [cur[0], cur[1], cur[2], next[0], next[1], next[2]];
  #| }

///|
fn find_standable_y(
  chunk_map : @ffi.JsValue,
  size : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> Int {
  for dy in 0..<4 {
    let candidate = wy - dy
    if is_walkable(chunk_map, size, wx, candidate, wz) {
      return candidate
    }
  }
  wy
}

///|
pub fn navigate_entity_to(
  entity_id : String,
  renderer : @render.GltfRenderer,
  chunk_map : @ffi.JsValue,
  size : Int,
  target_wx : Int,
  target_wy : Int,
  target_wz : Int,
) -> Unit {
  @ffi.console_err(
    "[nav] navigate_entity_to called for \{entity_id} target=(\{target_wx},\{target_wy},\{target_wz})",
  )
  jnav_clear(entity_id)
  ignore(target_wy)
  match @render.gltf_get_position(renderer, entity_id) {
    None =>
      @ffi.console_err("[nav] gltf_get_position returned None for \{entity_id}")
    Some(pos) => {
      @ffi.console_err("[nav] entity pos: (\{pos[0]}, \{pos[1]}, \{pos[2]})")
      let start_wx = pos[0].floor().to_int()
      let start_wz = pos[2].floor().to_int()
      let start_y = find_standable_y(
        chunk_map, size, start_wx, pos[1].floor().to_int(), start_wz,
      )
      @ffi.console_err(
        "[nav] start=(\{start_wx},\{start_y},\{start_wz}) target=(\{target_wx},\{target_wz})",
      )
      match find_path(
        chunk_map, size, start_wx, start_y, start_wz, target_wx, target_wz,
      ) {
        None => @ffi.console_err("[nav] find_path returned None - no path found")
        Some(nodes) => {
          @ffi.console_err("[nav] find_path found \{nodes.length()} nodes")
          let arrays = path_nodes_to_arrays(nodes)
          jnav_store(entity_id, arrays)
          guard arrays.length() > 1 else { return }
          let next = arrays[1]
          ignore(
            @render.gltf_look_at_xz(
              renderer, entity_id,
              next[0].to_double() + 0.5, next[2].to_double() + 0.5,
            ),
          )
        }
      }
    }
  }
}

///|
pub fn tick_entity_navigation(
  renderer : @render.GltfRenderer,
  delta : Double,
) -> Unit {
  let entity_ids = @render.gltf_entity_ids(renderer)
  for entity_id in entity_ids {
    let result = jnav_tick(entity_id, delta)
    guard !result.is_null() else { continue }
    let arr : Array[Int] = result.cast_to()
    guard arr.length() == 6 else {
      @ffi.console_err("[nav] tick: unexpected result len \{arr.length()}")
      continue
    }
    let wx = arr[0].to_double() + 0.5
    let wy = arr[1].to_double()
    let wz = arr[2].to_double() + 0.5
    ignore(@render.gltf_set_position(renderer, entity_id, wx, wy, wz))
    ignore(
      @render.gltf_look_at_xz(
        renderer, entity_id,
        arr[3].to_double() + 0.5, arr[5].to_double() + 0.5,
      ),
    )
  }
}
