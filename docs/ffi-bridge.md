# FFI Bridge

MoonBit-to-JavaScript interop layer handling global registration, opaque data bridges, and localStorage persistence.

## Prelude

- `global_set` / `cast_global_set`: set properties on `globalThis` — the primary mechanism for exposing MoonBit functions (`mc*` globals) to JS code
- `object_has` / `object_get` / `object_set`: property access on opaque JS objects
- `new_map` / `map_set` / `map_delete`: JavaScript `Map` creation and mutation — used for the chunk map, which JS reads for rendering but MoonBit owns
- `console_err`: error logging to browser console

The chunk map is intentionally an opaque `JsValue` — MoonBit stores tile arrays in it, JS accesses them by string key, but neither side can misinterpret the other's data.

## JsValue

An external MoonBit type with methods for undefined/null checks, string conversion, JSON serialization, and identity comparison (`Object.is`). `cast_from`/`cast_to` use `%identity` for zero-cost type coercion between MoonBit and JS representations.

## Save Bridge

Handles localStorage persistence:

- **`SAVE_STORAGE_KEY`**: `"mooncraft.save.v2"` — default key for the active save
- **`active_save_storage_key`**: reads `globalThis.mcSelectedSaveStorageKey` (set by the save menu); falls back to the default key
- **`load_saved_world_seed`**: parses saved JSON, reads `world.seed`, validates it's a finite number, returns as `UInt`
- **`load_saved_world_type`**: parses saved JSON, reads `world.worldType`, validates it's a string
- **`new_world_type`**: reads `globalThis.mcNewWorldType` (set by the save menu for new worlds)
- **`notify_block_changed`**: calls `globalThis.mcOnBlockChanged(wx, wy, wz, id)` if the callback exists — used by JS to trigger mesh updates

**WIP**: The save bridge reads V1 camelCase field names during seed/world-type loading (`worldType` instead of `world_type`). This is deliberate for backward compat with V1 saves that are migrated later.
