///|
pub const DEFAULT_API_TIMEOUT_MS : Int = 10_000

///|
pub const DEFAULT_DEMO_INTERVAL_MS : Int = 1_500

///|
/// Wait for an entity operation to become available, then invoke it once.
extern "js" fn invoke_entity_api(
  operation : String,
  entity_id : String,
  args : FixedArray[@ffi.JsValue],
  timeout_ms : Int,
) -> Unit =
  #| (method, entityId, args, timeoutMs) => {
  #|   const started = Date.now();
  #|   const timeout = Math.max(0, timeoutMs | 0);
  #|   const tick = () => {
  #|     const api = globalThis.mcGltfEntityApi;
  #|     if (api && typeof api[method] === "function") {
  #|       Promise.resolve(api[method](entityId, ...args)).catch((err) => {
  #|         console.warn(`[entity] ${method} failed`, entityId, ...args, err);
  #|       });
  #|       return;
  #|     }
  #|     if (Date.now() - started <= timeout) {
  #|       setTimeout(tick, 50);
  #|     } else {
  #|       console.warn(`[entity] ${method} api not ready`, entityId, ...args);
  #|     }
  #|   };
  #|   tick();
  #| }

///|
pub fn js_set_animation(
  entity_id : String,
  clip : String,
  timeout_ms : Int,
) -> Unit {
  invoke_entity_api("setAnimation", entity_id, [@ffi.cast(clip)], timeout_ms)
}

///|
pub fn js_set_texture(
  entity_id : String,
  texture_path : String,
  timeout_ms : Int,
) -> Unit {
  invoke_entity_api(
    "setTexture",
    entity_id,
    [@ffi.cast(texture_path)],
    timeout_ms,
  )
}

///|
pub fn js_set_rotation_quat(
  entity_id : String,
  x : Double,
  y : Double,
  z : Double,
  w : Double,
  timeout_ms : Int,
) -> Unit {
  invoke_entity_api(
    "setRotationQuat",
    entity_id,
    [@ffi.cast(x), @ffi.cast(y), @ffi.cast(z), @ffi.cast(w)],
    timeout_ms,
  )
}

///|
pub fn js_set_yaw(entity_id : String, yaw : Double, timeout_ms : Int) -> Unit {
  invoke_entity_api("setYaw", entity_id, [@ffi.cast(yaw)], timeout_ms)
}

///|
pub fn js_set_scale(
  entity_id : String,
  x : Double,
  y : Double,
  z : Double,
  timeout_ms : Int,
) -> Unit {
  invoke_entity_api(
    "setScale",
    entity_id,
    [@ffi.cast(x), @ffi.cast(y), @ffi.cast(z)],
    timeout_ms,
  )
}

///|
pub fn js_look_at_xz(
  entity_id : String,
  x : Double,
  z : Double,
  timeout_ms : Int,
) -> Unit {
  invoke_entity_api(
    "lookAtXz",
    entity_id,
    [@ffi.cast(x), @ffi.cast(z)],
    timeout_ms,
  )
}

///|
pub fn js_look_at_xyz(
  entity_id : String,
  x : Double,
  y : Double,
  z : Double,
  timeout_ms : Int,
) -> Unit {
  invoke_entity_api(
    "lookAtXyz",
    entity_id,
    [@ffi.cast(x), @ffi.cast(y), @ffi.cast(z)],
    timeout_ms,
  )
}

///|
pub extern "js" fn js_start_animation_cycle(
  entity_id : String,
  clips : FixedArray[String],
  interval_ms : Int,
  timeout_ms : Int,
) -> Unit =
  #| (entityId, clips, intervalMs, timeoutMs) => {
  #|   if (!Array.isArray(clips) || clips.length === 0) {
  #|     console.warn("[entity] startAnimationCycle requires non-empty clip list", entityId);
  #|     return;
  #|   }
  #|   const stateKey = "__mc_entity_animation_cycle_state";
  #|   const prev = globalThis[stateKey];
  #|   if (prev && prev.timer != null) {
  #|     clearInterval(prev.timer);
  #|   }
  #|   const started = Date.now();
  #|   const timeout = Math.max(0, timeoutMs | 0);
  #|   const interval = Math.max(200, intervalMs | 0);
  #|   const tickReady = () => {
  #|     const api = globalThis.mcGltfEntityApi;
  #|     if (!api || typeof api.setAnimation !== "function") {
  #|       if (Date.now() - started <= timeout) {
  #|         setTimeout(tickReady, 50);
  #|       } else {
  #|         console.warn("[entity] animation cycle api not ready", entityId);
  #|       }
  #|       return;
  #|     }
  #|     let clipIndex = 0;
  #|     const playNext = () => {
  #|       const clip = clips[clipIndex % clips.length];
  #|       clipIndex += 1;
  #|       Promise.resolve(api.setAnimation(entityId, clip)).catch((err) => {
  #|         console.warn("[entity] cycle setAnimation failed", entityId, clip, err);
  #|       });
  #|     };
  #|     playNext();
  #|     const timer = setInterval(playNext, interval);
  #|     globalThis[stateKey] = { entityId, timer };
  #|   };
  #|   tickReady();
  #| }

///|
pub extern "js" fn js_stop_animation_cycle() -> Unit =
  #| () => {
  #|   const stateKey = "__mc_entity_animation_cycle_state";
  #|   const state = globalThis[stateKey];
  #|   if (state && state.timer != null) {
  #|     clearInterval(state.timer);
  #|   }
  #|   globalThis[stateKey] = null;
  #| }

///|
pub fn set_animation(
  entity_id : String,
  clip : String,
  timeout_ms? : Int = DEFAULT_API_TIMEOUT_MS,
) -> Unit {
  js_set_animation(entity_id, clip, timeout_ms)
}

///|
pub fn set_texture(
  entity_id : String,
  texture_path : String,
  timeout_ms? : Int = DEFAULT_API_TIMEOUT_MS,
) -> Unit {
  js_set_texture(entity_id, texture_path, timeout_ms)
}

///|
pub fn set_rotation_quat(
  entity_id : String,
  x : Double,
  y : Double,
  z : Double,
  w : Double,
  timeout_ms? : Int = DEFAULT_API_TIMEOUT_MS,
) -> Unit {
  js_set_rotation_quat(entity_id, x, y, z, w, timeout_ms)
}

///|
pub fn set_yaw(
  entity_id : String,
  yaw : Double,
  timeout_ms? : Int = DEFAULT_API_TIMEOUT_MS,
) -> Unit {
  js_set_yaw(entity_id, yaw, timeout_ms)
}

///|
pub fn set_scale(
  entity_id : String,
  x : Double,
  y : Double,
  z : Double,
  timeout_ms? : Int = DEFAULT_API_TIMEOUT_MS,
) -> Unit {
  js_set_scale(entity_id, x, y, z, timeout_ms)
}

///|
pub fn look_at_xz(
  entity_id : String,
  x : Double,
  z : Double,
  timeout_ms? : Int = DEFAULT_API_TIMEOUT_MS,
) -> Unit {
  js_look_at_xz(entity_id, x, z, timeout_ms)
}

///|
pub fn look_at_xyz(
  entity_id : String,
  x : Double,
  y : Double,
  z : Double,
  timeout_ms? : Int = DEFAULT_API_TIMEOUT_MS,
) -> Unit {
  js_look_at_xyz(entity_id, x, y, z, timeout_ms)
}

///|
pub fn look_at_xzy(
  entity_id : String,
  x : Double,
  y : Double,
  z : Double,
  timeout_ms? : Int = DEFAULT_API_TIMEOUT_MS,
) -> Unit {
  look_at_xyz(entity_id, x, y, z, timeout_ms~)
}

///|
pub fn start_animation_cycle(
  entity_id : String,
  clips : FixedArray[String],
  interval_ms? : Int = DEFAULT_DEMO_INTERVAL_MS,
  timeout_ms? : Int = DEFAULT_API_TIMEOUT_MS,
) -> Unit {
  js_start_animation_cycle(entity_id, clips, interval_ms, timeout_ms)
}

///|
pub fn stop_animation_cycle() -> Unit {
  js_stop_animation_cycle()
}
