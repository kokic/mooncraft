///|
pub const SAVE_STORAGE_KEY : String = "mooncraft.save.v2"

///|
pub extern "js" fn active_save_storage_key(
  fallback? : String = SAVE_STORAGE_KEY,
) -> String =
  #| (fallback) => {
  #|   const selected = globalThis.mcSelectedSaveStorageKey;
  #|   return typeof selected === "string" && selected.length > 0
  #|     ? selected
  #|     : fallback;
  #| }

///|
pub extern "js" fn load_saved_world_seed(
  fallback : UInt,
  key? : String = SAVE_STORAGE_KEY,
) -> UInt =
  #| (fallback, key) => {
  #|   try {
  #|     const selected = globalThis.mcSelectedSaveStorageKey;
  #|     const storageKey = typeof selected === "string" && selected.length > 0
  #|       ? selected
  #|       : key;
  #|     const raw = globalThis.localStorage?.getItem(storageKey);
  #|     if (!raw) return fallback;
  #|     const parsed = JSON.parse(raw);
  #|     const seed = parsed?.world?.seed;
  #|     if (typeof seed !== "number" || !Number.isFinite(seed)) return fallback;
  #|     const value = Math.max(0, Math.floor(seed));
  #|     return value >>> 0;
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
  #|     const selected = globalThis.mcSelectedSaveStorageKey;
  #|     const storageKey = typeof selected === "string" && selected.length > 0
  #|       ? selected
  #|       : key;
  #|     const raw = globalThis.localStorage?.getItem(storageKey);
  #|     if (!raw) return fallback;
  #|     const parsed = JSON.parse(raw);
  #|     const worldType = parsed?.world?.worldType;
  #|     return typeof worldType === "string" ? worldType : fallback;
  #|   } catch (_) {
  #|     return fallback;
  #|   }
  #| }

///|
pub extern "js" fn new_world_type(
  fallback : String,
) -> String =
  #| (fallback) => {
  #|   const wt = globalThis.mcNewWorldType;
  #|   return typeof wt === "string" && wt.length > 0 ? wt : fallback;
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
