///|
pub const DEFAULT_API_TIMEOUT_MS : Int = 10_000

///|
pub const DEFAULT_DEMO_INTERVAL_MS : Int = 1_500

///|
pub extern "js" fn js_set_animation(
  entity_id : String,
  clip : String,
  timeout_ms : Int,
) -> Unit =
  #| (entityId, clip, timeoutMs) => {
  #|   const started = Date.now();
  #|   const timeout = Math.max(0, timeoutMs | 0);
  #|   const tick = () => {
  #|     const api = globalThis.mcGltfEntityApi;
  #|     if (api && typeof api.setAnimation === "function") {
  #|       Promise.resolve(api.setAnimation(entityId, clip)).catch((err) => {
  #|         console.warn("[entity] setAnimation failed", entityId, clip, err);
  #|       });
  #|       return;
  #|     }
  #|     if (Date.now() - started <= timeout) {
  #|       setTimeout(tick, 50);
  #|     } else {
  #|       console.warn("[entity] setAnimation api not ready", entityId, clip);
  #|     }
  #|   };
  #|   tick();
  #| }

///|
pub extern "js" fn js_set_texture(
  entity_id : String,
  texture_path : String,
  timeout_ms : Int,
) -> Unit =
  #| (entityId, texturePath, timeoutMs) => {
  #|   const started = Date.now();
  #|   const timeout = Math.max(0, timeoutMs | 0);
  #|   const tick = () => {
  #|     const api = globalThis.mcGltfEntityApi;
  #|     if (api && typeof api.setTexture === "function") {
  #|       Promise.resolve(api.setTexture(entityId, texturePath)).catch((err) => {
  #|         console.warn("[entity] setTexture failed", entityId, texturePath, err);
  #|       });
  #|       return;
  #|     }
  #|     if (Date.now() - started <= timeout) {
  #|       setTimeout(tick, 50);
  #|     } else {
  #|       console.warn("[entity] setTexture api not ready", entityId, texturePath);
  #|     }
  #|   };
  #|   tick();
  #| }

///|
pub extern "js" fn js_start_animation_demo(
  entity_id : String,
  interval_ms : Int,
  timeout_ms : Int,
) -> Unit =
  #| (entityId, intervalMs, timeoutMs) => {
  #|   const clips = [
  #|     "animation.zombie.walk",
  #|     "animation.zombie.attack",
  #|     "riding",
  #|     "none",
  #|   ];
  #|   const stateKey = "__mc_entity_anim_demo_state";
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
  #|         console.warn("[entity] animation demo api not ready", entityId);
  #|       }
  #|       return;
  #|     }
  #|     let clipIndex = 0;
  #|     const playNext = () => {
  #|       const clip = clips[clipIndex % clips.length];
  #|       clipIndex += 1;
  #|       Promise.resolve(api.setAnimation(entityId, clip)).catch((err) => {
  #|         console.warn("[entity] demo setAnimation failed", entityId, clip, err);
  #|       });
  #|     };
  #|     playNext();
  #|     const timer = setInterval(playNext, interval);
  #|     globalThis[stateKey] = { entityId, timer };
  #|   };
  #|   tickReady();
  #| }

///|
pub extern "js" fn js_stop_animation_demo() -> Unit =
  #| () => {
  #|   const stateKey = "__mc_entity_anim_demo_state";
  #|   const state = globalThis[stateKey];
  #|   if (state && state.timer != null) {
  #|     clearInterval(state.timer);
  #|   }
  #|   globalThis[stateKey] = null;
  #| }

///|
pub fn set_animation(entity_id : String, clip : String) -> Unit {
  js_set_animation(entity_id, clip, DEFAULT_API_TIMEOUT_MS)
}

///|
pub fn set_texture(entity_id : String, texture_path : String) -> Unit {
  js_set_texture(entity_id, texture_path, DEFAULT_API_TIMEOUT_MS)
}

///|
pub fn start_zombie_animation_demo() -> Unit {
  js_start_animation_demo(
    "zombie_0",
    DEFAULT_DEMO_INTERVAL_MS,
    DEFAULT_API_TIMEOUT_MS,
  )
}

///|
pub fn stop_animation_demo() -> Unit {
  js_stop_animation_demo()
}
