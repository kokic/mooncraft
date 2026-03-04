///|
pub const SAVE_STORAGE_KEY : String = "mooncraft.save.v1"

///|
pub extern "js" fn load_saved_world_seed(
  fallback : UInt64,
  key? : String = SAVE_STORAGE_KEY,
) -> UInt64 =
  #| (fallback, key) => {
  #|   try {
  #|     const raw = globalThis.localStorage?.getItem(key);
  #|     if (!raw) return fallback;
  #|     const parsed = JSON.parse(raw);
  #|     const seed = parsed?.world?.seed;
  #|     if (typeof seed !== "number" || !Number.isFinite(seed)) return fallback;
  #|     return Math.max(0, Math.floor(seed));
  #|   } catch (_) {
  #|     return fallback;
  #|   }
  #| }

///|
pub extern "js" fn load_saved_world_type(
  fallback : String,
  key? : String = SAVE_STORAGE_KEY,
) -> String =
  #| (fallback, key) => {
  #|   try {
  #|     const raw = globalThis.localStorage?.getItem(key);
  #|     if (!raw) return fallback;
  #|     const parsed = JSON.parse(raw);
  #|     const worldType = parsed?.world?.worldType;
  #|     return typeof worldType === "string" ? worldType : fallback;
  #|   } catch (_) {
  #|     return fallback;
  #|   }
  #| }

///|
pub extern "js" fn notify_block_changed(
  wx : Int,
  wy : Int,
  wz : Int,
  id : UInt,
) -> Unit =
  #| (wx, wy, wz, id) => {
  #|   const callback = globalThis.mcOnBlockChanged;
  #|   if (typeof callback === "function") {
  #|     callback(wx, wy, wz, id);
  #|   }
  #| }
